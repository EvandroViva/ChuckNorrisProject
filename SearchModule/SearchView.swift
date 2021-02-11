import SwiftUI
import ComposableArchitecture
import ChuckNorrisFactsCommon

struct SearchBar: View {
  @Binding var text: String
  var action: () -> ()
  
  @State private var isEditing = false
  
  var body: some View {
    HStack {
      
      TextField("Search", text: $text, onCommit: {
        action()
      })
      .keyboardType(.webSearch)
      .autocapitalization(.none)
      .padding(.horizontal, 25)
      .padding(7)
      .background(Color(UIColor.systemGray5))
      .cornerRadius(8)
      .overlay(
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.gray)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
          
          if isEditing {
            Button(action: {
              self.text = ""
            }) {
              Image(systemName: "multiply.circle.fill")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
            }
          }
        }
      )
      .padding(.horizontal, 10)
      .onTapGesture {
        self.isEditing = true
      }
      
      
      if isEditing {
        Button(action: {
          self.isEditing = false
          self.text = ""
          UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }) {
          Text("Cancel")
        }
        .padding(.trailing, 10)
        .transition(.move(edge: .trailing))
        .animation(.default)
      }
    }
  }
}

public struct ItemView: View {
  @State public var text: String
  
  public var body: some View {
    Text(text)
      .padding(.all, 4)
      .font(.body)
      .background(Color.clear)
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.blue, lineWidth: 1)
      )
      .fixedSize()
  }
}

public struct SearchView: View {
  let store: Store<SearchState, SearchAction>
  
  public var body: some View {
    WithViewStore(store) { viewStore in
      VStack(alignment: .leading, spacing: 4) {
        SearchBar(text: viewStore.binding(get: { $0.searchTerm }, send: SearchAction.searchTermChanged)) {
          viewStore.send(SearchAction.keyboardEnterButtonTapped)
        }
        Text("Suggestions:")
          .padding(.top, 5)
        WrapHStack(items: viewStore.suggestions.withIndex()) { (index, value) in
          Button(action: {
            viewStore.send(SearchAction.suggestionButtonTapped(index))
          }) {
            ItemView(text: value.capitalized)
          }
        }
        .padding(.leading, 4)
        if viewStore.pastSearches.count > 0 {
          Text("Past Searches:")
            .padding(.top, 5)
          VStack(alignment: .leading, spacing: 4) {
            ForEach(viewStore.pastSearches.reversed().withIndex(), id: \.1) { (index, value) in
              Button(action: {
                viewStore.send(SearchAction.pastSearchButtonTapped(index))
              }) {
                Text(value)
                  .padding(.vertical, 8)
                  .foregroundColor(.gray)
              }
            }
          }
          .padding(.leading, 4)
        }
        Spacer()
      }
      .padding(.all, 7)
      .onAppear {
        viewStore.send(.loadSearchedTerms)
      }
      .alert(isPresented: viewStore.binding(get: { $0.showingAlert }, send: SearchAction.alertDismissed)) {
        Alert(title: Text("Most likely Chuck Norris turned off all internet..."), message: Text("Try again. If you are worthy..."), dismissButton: .default(Text("Ok!")))
      }
    }
    .navigationBarTitle("")
    .navigationBarHidden(true)
  
  }
  
  public init(store: Store<SearchState, SearchAction>) {
    self.store = store
  }
}

struct SearchView_Previews: PreviewProvider {
  
  static var previews: some View {
    var state = SearchState()
    state.suggestions = ["Games", "Sports", "Dev", "Science", "Technology", "Music", "Travel", "Carrer"]
    state.pastSearches = ["Trump", "Git"]
    return Group {
      SearchView(store: Store(
                  initialState: state,
                  reducer: searchReducer,
                  environment: SearchEnvironment(
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                    chuckNorrisClient: .mock(),
                    userDefaultsClient: .mock()
                  )))
      SearchView(store: Store(
                  initialState: state,
                  reducer: searchReducer,
                  environment: SearchEnvironment(
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                    chuckNorrisClient: .mock(),
                    userDefaultsClient: .mock()
                  ))).preferredColorScheme(.dark)
    }
  }
}
