import SwiftUI
import FactsModule
import ComposableArchitecture
import SearchModule

@main
struct ChuckNorrisFactsApp: App {
  var body: some Scene {
    WindowGroup {
      FactsView(
        store: Store(
          initialState: FactsState(facts: []),
          reducer: factsReducer,
          environment: FactsEnvironment(
            mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
            chuckNorrisClient: .live,
            userDefaultsClient: .live
          )
        )
      )
    }
  }
}
