import Combine
import ComposableArchitecture
import SearchModule

public struct FactsState: Equatable {
  var facts: IdentifiedArrayOf<FactState> = []
  var search = SearchState()
  var searchViewShown = false
  
  public init(facts: IdentifiedArrayOf<FactState> = [], search: SearchState = SearchState(), searchViewControllerShown: Bool = false) {
    self.facts = facts
    self.search = search
    self.searchViewShown = searchViewControllerShown
  }
}

public enum FactsAction: Equatable {
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
    Reducer<FactsState, FactsAction, FactsEnvironment> { state, action, enviroment in

      switch action {
        case .searchButtonTapped:
          state.searchViewShown = true
          return .none
        case .dismissSearchView:
          state.searchViewShown = false
          return .none
        case let .search(searchAction):
          switch searchAction {
            case let .chuckNorrisFactsResponse(_, .success(facts)):
              state.facts = IdentifiedArrayOf.init(facts.map(FactState.init))
              state.searchViewShown = false
              return .none
            default:
              return .none
          }
        case .fact(id: let id, action: let action):
          return .none
      }
    }.debug()
  )
  
