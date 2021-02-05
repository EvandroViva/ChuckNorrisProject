import SwiftUI
import ComposableArchitecture
import SearchModule

public struct FactsView: View {
  let store: Store<FactsState, FactsAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        ZStack {
            VStack(alignment: .leading) {
              ScrollView {
                LazyVStack(pinnedViews: .sectionHeaders) {
                  ForEachStore(
                    self.store.scope(state: { $0.facts }, action: FactsAction.fact(id:action:)),
                    content: FactCellView.init(store:))
                }
              }
            }
        }
        .navigationBarItems(
          trailing:
            Button(action: { viewStore.send(.searchButtonTapped) }) {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.blue)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            }
        )
        .navigationTitle("Chuck Norris Facts")
      }
      .sheet(isPresented: viewStore.binding(get: { $0.searchViewShown }, send: .dismissSearchView)) {
        SearchView(store:
                    self.store.scope(
                      state: { $0.search },
                      action: FactsAction.search)
        )
      }
    }
  }
  
  public init(store: Store<FactsState, FactsAction>) {
    self.store = store
  }
}

struct FactsView_Previews: PreviewProvider {
  static let factsTexts: [(String,[String])] = [
    ("Chuck Norris finished every Call of Duty games in less than 15 minutes..........without shooting a single bullet.", ["dev"]),
    ("If Chuck Norris were a PC or Mac he\'d be a Mac because you can\'t play games with Chuck Norris", ["dev", "explicit"]),
    ("Why did Chuck Norris hasn\'t appeared on any mortal kombat games. Simple, the name says it all. \"mortal\". Also there won\'t be any fatality tha will work on him, he will just roundhouse kick anyone either he wins or loose.", []),
  ]
  static var previews: some View {
    Group {
      FactsView(store: Store(
        initialState: FactsState(facts:
                                  IdentifiedArrayOf(factsTexts.enumerated().map {
                                    FactState(icon_url: "", id: "\($0.offset)", url: "", value: $0.element.0, categories: $0.element.1)
                                  })
        ),
        reducer: factsReducer,
        environment: FactsEnvironment(
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          chuckNorrisClient: .mock(),
          userDefaultsClient: .mock()
        )
      ))
      FactsView(store: Store(
        initialState: FactsState(facts:
                                  IdentifiedArrayOf(factsTexts.enumerated().map {
                                    FactState(icon_url: "", id: "\($0.offset)", url: "", value: $0.element.0, categories: $0.element.1)
                                  })
        ),
        reducer: factsReducer,
        environment: FactsEnvironment(
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          chuckNorrisClient: .mock(),
          userDefaultsClient: .mock()
        )
      )).preferredColorScheme(.dark)
    }
    .previewDevice("iPhone 11 Pro")
  }
}
