import SwiftUI
import ComposableArchitecture
import SearchModule
import ChuckNorrisFactsCommon

public struct ItemView: View {
  @State public var text: String
  
  public var body: some View {
    Text(text)
      .padding(.horizontal, 8)
      .padding(.vertical, 1)
      .font(Font.footnote.bold())
      .background(Color.blue)
      .foregroundColor(Color.white)
      .cornerRadius(12)
      .fixedSize()
  }
}

public struct FactCellView: View {
  let store: Store<FactState, FactAction>
  
  public var body: some View {
    WithViewStore(store) { viewStore in
      ZStack {
        VStack {
          Text(viewStore.fact.value)
            .padding(.top, 10)
            .padding(.bottom, 2)
            .padding(.horizontal, 4)
            .frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0,
                   maxHeight: .infinity,
                   alignment: .topLeading
            )
          HStack {
            WrapHStack(items: viewStore.categories.withIndex()) { (index, value) in
              ItemView(text: value.capitalized)
            }
            Spacer()
          }
          .padding(.bottom, 4)
        }
        .padding(.horizontal, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .mask(RoundedRectangle(cornerRadius: 10.0))
        .shadow(radius: 3)
      }
      .padding(.vertical, 5)
      .padding(.horizontal, 15)
    }
  }
}
