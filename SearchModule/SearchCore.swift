import ComposableArchitecture

public struct SearchState: Equatable {
  var isPresented = true
  var searchTerm = ""
  var suggestions: [String] = ["games", "sports", "dev", "science", "technology", "music", "travel", "carrer"]
  var pastSearches: [String] = []
  var showingAlert = false
  
  public init() { }
}

public enum SearchAction: Equatable {
  case loadCategories
  case loadSearchedTerms
  case searchTermChanged(String)
  case keyboardEnterButtonTapped
  case suggestionButtonTapped(Int)
  case pastSearchButtonTapped(Int)
  case alertDismissed
  
  case loadedSearchedTermsResponse(Result<[String], Never>)
  case loadedCategoriesResponse(Result<[String], Never>)
  case chuckNorrisFactsResponse(source: SourceAction, Result<[Fact], ChuckNorrisClient.Failure>)
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
      
    case let .searchTermChanged(value):
      state.searchTerm = value
      return .none
      
    case .keyboardEnterButtonTapped:
      return environment.chuckNorrisClient
        .search(state.searchTerm)
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map { (.search, $0) }
        .map(SearchAction.chuckNorrisFactsResponse)
      
    case let .suggestionButtonTapped(index):
      // TODO: What to do if the index is out of range?
      let category = state.suggestions[index]
      return environment.chuckNorrisClient
        .search(category)
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map { (.suggestion, $0) }
        .map(SearchAction.chuckNorrisFactsResponse)
      
    case let .pastSearchButtonTapped(index):
      // TODO: What to do if the index is out of range?
      let term = state.pastSearches[index]
      
      return environment.chuckNorrisClient
        .search(term)
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map { (.pastSearch, $0) }
        .map(SearchAction.chuckNorrisFactsResponse)
    
    case .alertDismissed:
      return .none
      
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
      
    case .chuckNorrisFactsResponse(_, .failure(_)):
      state.showingAlert = true
      return .none
      
    case let .chuckNorrisCategoriesResponse(.success(categories)):
      state.suggestions = categories.shuffled().suffix(8).sorted()
      return environment.userDefaultsClient
        .save(categoriesListKeyname, categories)
        .fireAndForget()
      
    case .chuckNorrisCategoriesResponse(.failure(_)):
      return .none
  }
}

private let savedSearchedTermsListKeyname = "savedSearchedTermsList"
private let categoriesListKeyname = "categoriesList"
