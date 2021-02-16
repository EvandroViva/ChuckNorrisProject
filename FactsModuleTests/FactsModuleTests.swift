import ComposableArchitecture
import XCTest
import SearchModule
import ChuckNorrisFactsCommon

@testable import FactsModule

class FactsModuleTests: XCTestCase {
  let scheduler = DispatchQueue.testScheduler

  func testOpenSearchView() {
    let store = TestStore(
      initialState: .init(),
      reducer: factsReducer,
      environment: FactsEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .send(.searchButtonTapped) {
        $0.searchViewShown = true
      },
      .send(.dismissSearchView) {
        $0.searchViewShown = false
      }
    )
  }
  
  func testOnAppear() {
    let store = TestStore(
      initialState: .init(),
      reducer: factsReducer,
      environment: FactsEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.categories = { Effect(error: .invalidResponse) }
        $0.userDefaultsClient.load = { _ in Effect(value: []) }
        $0.userDefaultsClient.loadData = { _ in Effect(value: mockLocalDataEncoded) }
      },
      .send(.onAppear),
      .receive(.search(.loadCategories)),
      .receive(.search(.loadLocalData)),
      .do { self.scheduler.advance() },
      .receive(.search(.loadedCategoriesResponse(.success([])))),
      .receive(.search(.loadedLocalData(.success(mockLocalData)))) {
        $0.search.localData = mockLocalData
        var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970))
        $0.facts = IdentifiedArrayOf.init(mockLocalData.facts.map { $0.1 }.sorted { $0.id < $1.id }.shuffled(using: &generator).prefix(10).map(FactState.init))
      },
      .receive(.search(.chuckNorrisCategoriesResponse(.failure(.invalidResponse))))
    )
  }
  
  func testDimissSearchViewOnSearch() {
    let store = TestStore(
      initialState: .init(),
      reducer: factsReducer,
      environment: FactsEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.search = { _ in Effect(value: mockFacts) }
        $0.userDefaultsClient.load = { _ in Effect(value: []) }
        $0.userDefaultsClient.save = { _, _ in .none }
        $0.userDefaultsClient.loadData = { _ in Effect(value: nil) }
        $0.userDefaultsClient.saveData = { _, _ in .none }
      },
      .send(.searchButtonTapped) {
        $0.searchViewShown = true
      },
      .send(.search(.searchTerm(.search, "s"))) {
        $0.isLoading = true
        $0.searchViewShown = false
      },
      .do { self.scheduler.advance() },
      .receive(.search(.saveFactsAndResponse(.search, "s", .success(mockFacts)))) { state in
        state.search.localData.terms["s"] = mockFacts.map { $0.id }
        mockFacts.forEach { state.search.localData.facts[$0.id] = $0 }
      },
      .receive(.search(.chuckNorrisFactsResponse(.search, .success(mockFacts)))) {
        $0.facts = IdentifiedArrayOf.init(mockFacts.map(FactState.init))
        $0.isLoading = false
        $0.search.pastSearches = [""]
        $0.search.searchTerm = ""
        $0.search.isPresented = false
      }
    )
  }
  
  func testDimissSearchViewOnSearchFailure() {
    let store = TestStore(
      initialState: .init(),
      reducer: factsReducer,
      environment: FactsEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.search = { _ in Effect(error: .invalidResponse) }
        $0.userDefaultsClient.load = { _ in Effect(value: []) }
        $0.userDefaultsClient.loadData = { _ in Effect(value: nil) }
      },
      .send(.searchButtonTapped) {
        $0.searchViewShown = true
      },
      .send(.search(.searchTerm(.search, "s"))) {
        $0.isLoading = true
        $0.searchViewShown = false
      },
      .do { self.scheduler.advance() },
      .receive(.search(.saveFactsAndResponse(.search, "s", .failure(.invalidResponse)))),
      .receive(.search(.chuckNorrisFactsResponse(.search, .failure(.invalidResponse)))) {
        $0.search.showingAlert = true
        $0.isLoading = false
        $0.searchViewShown = true
      }
    )
  }
  
  // Facts
  
  func testDimissSearchViewOnSearchFailure1() {
    var state = FactsState()
    state.facts = IdentifiedArrayOf.init(mockFacts.map(FactState.init))
    
    let store = TestStore(
      initialState: state,
      reducer: factsReducer,
      environment: FactsEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .send(.fact(id: "0", action: .shareLinkButtonTapped)) {
        $0.facts[0].showSheet = true
      },
      .send(.fact(id: "0", action: .dismissSheet)) {
        $0.facts[0].showSheet = false
      }
    )
  }


}

let factsTexts: [(String,[String])] = [
  ("Chuck Norris finished every Call of Duty games in less than 15 minutes..........without shooting a single bullet.", ["dev"]),
  ("If Chuck Norris were a PC or Mac he\'d be a Mac because you can\'t play games with Chuck Norris", ["dev", "explicit"]),
  ("Why did Chuck Norris hasn\'t appeared on any mortal kombat games. Simple, the name says it all. \"mortal\". Also there won\'t be any fatality tha will work on him, he will just roundhouse kick anyone either he wins or loose.", []),
]
let mockFacts: [Fact] = factsTexts.enumerated().map {
  Fact(icon_url: "", id: "\($0.offset)", url: "", value: $0.element.0, categories: $0.element.1)
}
let mockCategories = ["animal","career","celebrity","dev","explicit","fashion","food","history","money","movie","music","political","religion","science","sport","travel"]
let mockLocalData: SearchState.LocalData = {
  var localData = SearchState.LocalData.empty
  localData.terms["s"] = mockFacts.map { $0.id }
  mockFacts.forEach { localData.facts[$0.id] = $0 }
  return localData
}()
let mockLocalDataEncoded = try! JSONEncoder().encode(mockLocalData)
