import ComposableArchitecture
import Combine
import ChuckNorrisFactsCommon

public struct SearchState: Equatable {
  public var isPresented = true
  public var searchTerm = ""
  public var suggestions: [String] = []
  public var pastSearches: [String] = []
  public var showingAlert = false
  public var localData = LocalData.empty
  
  public init() { }
  
  public struct LocalData: Codable, Equatable {
    public var terms: [String: [String]]
    public var facts: [String: Fact]
    
    public static var empty = LocalData(terms: [:], facts: [:])
  }
}

public enum SearchAction: Equatable {
  case loadCategories
  case loadSearchedTerms
  case loadLocalData
  case searchTermChanged(String)
  case keyboardEnterButtonTapped
  case suggestionButtonTapped(Int)
  case pastSearchButtonTapped(Int)
  case searchTerm(SourceAction, String)
  case alertDismissed
  
  case loadedSearchedTermsResponse(Result<[String], Never>)
  case loadedCategoriesResponse(Result<[String], Never>)
  case loadedLocalData(Result<SearchState.LocalData?, Never>)
  case chuckNorrisFactsResponse(SourceAction, Result<[Fact], ChuckNorrisClient.Failure>)
  case saveFactsAndResponse(SourceAction, String, Result<[Fact], ChuckNorrisClient.Failure>)
  case chuckNorrisCategoriesResponse(Result<[String], ChuckNorrisClient.Failure>)
  
  public enum SourceAction {
    case search
    case suggestion
    case pastSearch
  }
}

public struct SearchEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var chuckNorrisClient: ChuckNorrisClient
  var userDefaultsClient: UserDefaultsClient
  
  public init(mainQueue: AnySchedulerOf<DispatchQueue>, chuckNorrisClient: ChuckNorrisClient, userDefaultsClient: UserDefaultsClient) {
    self.mainQueue = mainQueue
    self.chuckNorrisClient = chuckNorrisClient
    self.userDefaultsClient = userDefaultsClient
  }
}

public let searchReducer = Reducer<SearchState, SearchAction, SearchEnvironment> { (state, action, environment) -> Effect<SearchAction, Never> in
  switch action {
    case .loadCategories:
      return environment.userDefaultsClient
        .load(categoriesListKeyname)
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map(SearchAction.loadedCategoriesResponse)
      
    case .loadSearchedTerms:
      return environment.userDefaultsClient
        .load(savedSearchedTermsListKeyname)
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map(SearchAction.loadedSearchedTermsResponse)
    
    case .loadLocalData:
      return environment.userDefaultsClient
        .loadData(localDataKeyname)
        .map({ (data) -> SearchState.LocalData? in
          guard let data = data else { return nil }
          return try? JSONDecoder().decode(SearchState.LocalData.self, from: data)
        })
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map(SearchAction.loadedLocalData)
      
    case let .searchTermChanged(value):
      state.searchTerm = value
      return .none
      
    case .keyboardEnterButtonTapped:
      return Effect(value: SearchAction.searchTerm(.search, state.searchTerm))
      
    case let .suggestionButtonTapped(index):
      let category = state.suggestions[index]
      return Effect(value: SearchAction.searchTerm(.suggestion, category))
      
    case let .pastSearchButtonTapped(index):
      let term = state.pastSearches[index]
      return Effect(value: SearchAction.searchTerm(.pastSearch, term))
      
    case let .searchTerm(source, term):
      if let list = state.localData.terms[term.lowercased()] {
        let facts = list.compactMap { state.localData.facts[$0] }
        return Effect(value: SearchAction.chuckNorrisFactsResponse(source, .success(facts)))
      }
      return environment.chuckNorrisClient
        .search(term)
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map { (source, term, $0) }
        .map(SearchAction.saveFactsAndResponse)
    
    case .alertDismissed:
      state.showingAlert = false
      return .none
      
    case let .loadedSearchedTermsResponse(.success(terms)):
      state.pastSearches = terms
      return .none
      
    case let .loadedCategoriesResponse(.success(categories)):
      if categories.isEmpty {
        return environment.chuckNorrisClient
          .categories()
          .receive(on: environment.mainQueue)
          .catchToEffect()
          .map(SearchAction.chuckNorrisCategoriesResponse)
      }
      return Effect(value: SearchAction.chuckNorrisCategoriesResponse(.success(categories)))
        .eraseToEffect()
      
    case let .loadedLocalData(.success(localData)):
      state.localData = localData ?? state.localData
      return .none
      
    case let .saveFactsAndResponse(source, term, .success(facts)):
      state.localData.terms[term.lowercased()] = facts.map { $0.id }
      facts.forEach { state.localData.facts[$0.id] = $0 }
      let data = try! JSONEncoder().encode(state.localData)
      return .concatenate(
        environment.userDefaultsClient
          .saveData(localDataKeyname, data)
          .fireAndForget(),
        Effect(value: SearchAction.chuckNorrisFactsResponse(source, .success(facts)))
      )
      
    case let .saveFactsAndResponse(source, term, .failure(error)):
      return Effect(value: SearchAction.chuckNorrisFactsResponse(source, .failure(error)))
      
    case let .chuckNorrisFactsResponse(source, .success(facts)):
      switch source {
        case .search:
          state.pastSearches.append(state.searchTerm)
          state.searchTerm = ""
        case .suggestion:
          break
        case .pastSearch:
          break
      }
      state.isPresented = false
      return environment.userDefaultsClient
        .save(savedSearchedTermsListKeyname, state.pastSearches)
        .fireAndForget()
      
    case .chuckNorrisFactsResponse(_, .failure(_)):
      state.showingAlert = true
      return .none
      
    case let .chuckNorrisCategoriesResponse(.success(categories)):
      var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970))
      state.suggestions = categories.shuffled(using: &generator).suffix(8).sorted()
      return environment.userDefaultsClient
        .save(categoriesListKeyname, categories)
        .fireAndForget()
      
    case .chuckNorrisCategoriesResponse(.failure(_)):
      return .none
  }
}

private let savedSearchedTermsListKeyname = "savedSearchedTermsList"
private let categoriesListKeyname = "categoriesList"
private let localDataKeyname = "localData"
