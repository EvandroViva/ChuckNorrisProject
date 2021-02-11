import Combine
import ComposableArchitecture
import SearchModule

public struct FactsState: Equatable {
  var facts: IdentifiedArrayOf<FactState> = []
  var search = SearchState()
  var searchViewShown = false
  var isLoading = false
  
  public init(facts: IdentifiedArrayOf<FactState> = [], search: SearchState = SearchState(), searchViewControllerShown: Bool = false) {
    self.facts = facts
    self.search = search
    self.searchViewShown = searchViewControllerShown
  }
}

public enum FactsAction: Equatable {
  case onAppear
  case searchButtonTapped
  case dismissSearchView
  case search(SearchAction)
  case fact(id: String, action: FactAction)
}

public struct FactsEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var chuckNorrisClient: ChuckNorrisClient
  var userDefaultsClient: UserDefaultsClient
  
  public init(mainQueue: AnySchedulerOf<DispatchQueue>, chuckNorrisClient: ChuckNorrisClient, userDefaultsClient: UserDefaultsClient) {
    self.mainQueue = mainQueue
    self.chuckNorrisClient = chuckNorrisClient
    self.userDefaultsClient = userDefaultsClient
  }
}

public let factsReducer =
  Reducer.combine(
    searchReducer.pullback(
      state: \.search,
      action: /FactsAction.search,
      environment: {
        SearchEnvironment(
          mainQueue: $0.mainQueue,
          chuckNorrisClient: $0.chuckNorrisClient,
          userDefaultsClient: $0.userDefaultsClient
        ) }),
    factReducer.forEach(
      state: \.facts,
      action: /FactsAction.fact(id:action:),
      environment: { _ in FactEnvironment() }
    ),
    Reducer<FactsState, FactsAction, FactsEnvironment> { state, action, environment in

      switch action {
        case .onAppear:
          return .concatenate(
            Effect(value: FactsAction.search(SearchAction.loadCategories)),
            Effect(value: FactsAction.search(SearchAction.loadLocalData))
          )
        case .searchButtonTapped:
          state.searchViewShown = true
          return .none
        case .dismissSearchView:
          state.searchViewShown = false
          return .none
        case let .search(searchAction):
          switch searchAction {
            case .keyboardEnterButtonTapped, .suggestionButtonTapped(_), .pastSearchButtonTapped(_):
              state.isLoading = true
              state.searchViewShown = false
              return .none
            case let .chuckNorrisFactsResponse(_, .success(facts)):
              state.isLoading = false
              state.facts = IdentifiedArrayOf.init(facts.map(FactState.init))
              return .none
            case let .chuckNorrisFactsResponse(_, .failure(error)):
              state.isLoading = false
              state.searchViewShown = true
              return .none
            case let .loadedLocalData(.success(localData)):
              guard let localData = localData else { return .none }
              state.facts = IdentifiedArrayOf.init(localData.facts.map { $0.1 }.shuffled().prefix(10).map(FactState.init))
              return .none
            default:
              return .none
          }
        case .fact(id: let id, action: let action):
          return .none
      }
    }.debug()
  )
  
