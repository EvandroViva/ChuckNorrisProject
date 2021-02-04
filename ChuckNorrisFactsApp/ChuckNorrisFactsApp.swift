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
            chuckNorrisClient: .mock(search: { _ in .none }, random: { _ in .none }),
            userDefaultsClient: .mock(load: { _ in .none }, save: { _, _ in .none })
          )
        )
      )
    }
  }
}
