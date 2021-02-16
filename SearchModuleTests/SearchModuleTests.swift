import ComposableArchitecture
import XCTest
import ChuckNorrisFactsCommon

@testable import SearchModule

class SearchTests: XCTestCase {
  let scheduler = DispatchQueue.testScheduler
  
  func testSearchAndClearQuery() {
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.search = { _ in Effect(value: mockFacts) }
        $0.userDefaultsClient.save = { _, _ in .none }
        $0.userDefaultsClient.saveData = { _, _ in .none }
      },
      .send(.searchTermChanged("S")) {
        $0.searchTerm = "S"
      },
      .send(.keyboardEnterButtonTapped),
      .receive(.searchTerm(.search, "S")),
      .do { self.scheduler.advance() },
      .receive(.saveFactsAndResponse(.search, "S", .success(mockFacts))) { state in
        state.localData.terms["s"] = mockFacts.map { $0.id }
        mockFacts.forEach { state.localData.facts[$0.id] = $0 }
      },
      .receive(.chuckNorrisFactsResponse(.search, .success(mockFacts))) {
        $0.pastSearches = ["S"]
        $0.searchTerm = ""
        $0.isPresented = false
      }
    )
  }
  
  func testSearchFailure() {
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.search = { _ in Effect(error: .invalidResponse) }
      },
      .send(.searchTermChanged("S")) {
        $0.searchTerm = "S"
      },
      .send(.keyboardEnterButtonTapped),
      .receive(.searchTerm(.search, "S")),
      .do { self.scheduler.advance() },
      .receive(.saveFactsAndResponse(.search, "S", .failure(.invalidResponse))),
      .receive(.chuckNorrisFactsResponse(.search, .failure(.invalidResponse))) {
        $0.showingAlert = true
      },
      .send(.alertDismissed) {
        $0.showingAlert = false
      }
    )
  }
  
  func testTapOnSuggestion() {
    
    var state = SearchState()
    state.suggestions = ["games", "sports", "dev", "science", "technology", "music", "travel", "carrer"]
    
    let store = TestStore(
      initialState: state,
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.search = { _ in Effect(value: mockFacts) }
        $0.userDefaultsClient.save = { _, _ in .none }
        $0.userDefaultsClient.saveData = { _, _ in .none }
      },
      .send(.suggestionButtonTapped(0)),
      .receive(.searchTerm(.suggestion, "games")),
      .do { self.scheduler.advance() },
      .receive(.saveFactsAndResponse(.suggestion, "games", .success(mockFacts))) { state in
        state.localData.terms["games"] = mockFacts.map { $0.id }
        mockFacts.forEach { state.localData.facts[$0.id] = $0 }
      },
      .receive(.chuckNorrisFactsResponse(.suggestion, .success(mockFacts))) {
        $0.isPresented = false
      }
    )
  }
  
  func testTapOnPastSearchTerm() {
    
    var state = SearchState()
    state.pastSearches = ["sports", "dev"]
    
    let store = TestStore(
      initialState: state,
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.search = { _ in Effect(value: mockFacts) }
        $0.userDefaultsClient.save = { _, _ in .none }
        $0.userDefaultsClient.saveData = { _, _ in .none }
      },
      .send(.pastSearchButtonTapped(1)),
      .receive(.searchTerm(.pastSearch, "dev")),
      .do { self.scheduler.advance() },
      .receive(.saveFactsAndResponse(.pastSearch, "dev", .success(mockFacts))) { state in
        state.localData.terms["dev"] = mockFacts.map { $0.id }
        mockFacts.forEach { state.localData.facts[$0.id] = $0 }
      },
      .receive(.chuckNorrisFactsResponse(.pastSearch, .success(mockFacts))) {
        $0.isPresented = false
      }
    )
  }
  
  func testLoadSuggestions() {
    
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.categories = { Effect(value: mockCategories) }
        $0.userDefaultsClient.load = { _ in Effect(value: []) }
        $0.userDefaultsClient.save = { _, _ in .none }
      },
      .send(.loadCategories),
      .do { self.scheduler.advance() },
      .receive(.loadedCategoriesResponse(.success([]))),
      .receive(.chuckNorrisCategoriesResponse(.success(mockCategories))) {
        var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970))
        $0.suggestions = mockCategories.shuffled(using: &generator).suffix(8).sorted()
      }
    )
  }
  
  func testLoadSuggestionsFailure() {
    
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.chuckNorrisClient.categories = { Effect(error: .invalidResponse) }
        $0.userDefaultsClient.load = { _ in Effect(value: []) }
      },
      .send(.loadCategories),
      .do { self.scheduler.advance() },
      .receive(.loadedCategoriesResponse(.success([]))),
      .receive(.chuckNorrisCategoriesResponse(.failure(.invalidResponse)))
    )
  }
  
  // Local Tests
  
  func testLoadLocalData() {
    
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.userDefaultsClient.loadData = { _ in Effect(value: mockLocalDataEncoded) }
      },
      .send(.loadLocalData),
      .do { self.scheduler.advance() },
      .receive(.loadedLocalData(.success(mockLocalData))) {
        $0.localData = mockLocalData
      }
    )
  }
  
  func testLoadLocalDataFailure() {
    
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.userDefaultsClient.loadData = { _ in Effect(value: nil) }
      },
      .send(.loadLocalData),
      .do { self.scheduler.advance() },
      .receive(.loadedLocalData(.success(nil)))
    )
  }
  
  func testLoadSearchedTerms() {
    
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.userDefaultsClient.load = { _ in Effect(value: mockCategories) }
      },
      .send(.loadSearchedTerms),
      .do { self.scheduler.advance() },
      .receive(.loadedSearchedTermsResponse(.success(mockCategories))) {
        $0.pastSearches = mockCategories
      }
    )
  }
  
  func testLoadSuggestionsLocal() {
    
    let store = TestStore(
      initialState: .init(),
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.userDefaultsClient.load = { _ in Effect(value: mockCategories) }
        $0.userDefaultsClient.save = { _, _ in .none }
      },
      .send(.loadCategories),
      .do { self.scheduler.advance() },
      .receive(.loadedCategoriesResponse(.success(mockCategories))),
      .receive(.chuckNorrisCategoriesResponse(.success(mockCategories))) {
        var generator = SeededGenerator(seed: UInt64(Date().timeIntervalSince1970))
        $0.suggestions = mockCategories.shuffled(using: &generator).suffix(8).sorted()
      }
    )
  }
  
  func testSearchAndClearQueryLocal() {
    
    var state = SearchState()
    state.localData = mockLocalData
    
    let store = TestStore(
      initialState: state,
      reducer: searchReducer,
      environment: SearchEnvironment(
        mainQueue: self.scheduler.eraseToAnyScheduler(),
        chuckNorrisClient: .mock(),
        userDefaultsClient: .mock()
      )
    )
    
    store.assert(
      .environment {
        $0.userDefaultsClient.save = { _, _ in .none }
        $0.userDefaultsClient.saveData = { _, _ in .none }
      },
      .send(.searchTermChanged("S")) {
        $0.searchTerm = "S"
      },
      .send(.keyboardEnterButtonTapped),
      .receive(.searchTerm(.search, "S")),
      .receive(.chuckNorrisFactsResponse(.search, .success(mockFacts))) {
        $0.pastSearches = ["S"]
        $0.searchTerm = ""
        $0.isPresented = false
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
