import Combine
import ComposableArchitecture
import SearchModule

public struct FactState: Equatable, Identifiable {
  public var id: String
  public var fact: Fact
  public var categories: [String] {
    return fact.categories.isEmpty ? ["Uncategorized"] : fact.categories
  }
  
  public var showSheet = false
  
  public init(icon_url: String, id: String, url: String, value: String, categories: [String]) {
    self.fact = Fact(icon_url: icon_url, id: id, url: url, value: value, categories: categories)
    self.id = id
  }
  
  public init(fact: Fact) {
    self.fact = fact
    self.id = fact.id
  }
}

public enum FactAction: Equatable {
  case shareLinkButtonTapped
  case dismissSheet
}

public struct FactEnvironment {
}

public let factReducer = Reducer<FactState, FactAction, FactEnvironment> { state, action, enviroment in
  switch action {
    
    case .shareLinkButtonTapped:
      state.showSheet = true
      return .none
    case .dismissSheet:
      state.showSheet = false
      return .none
  }
}
