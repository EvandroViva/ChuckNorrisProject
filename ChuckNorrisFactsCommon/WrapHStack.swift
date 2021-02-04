import SwiftUI

struct SizePref: PreferenceKey {
  static var defaultValue: CGSize = .init(width: 0, height: 0)
  static func reduce(value: inout CGSize , nextValue: () -> CGSize) {
    value = nextValue()
  }
}

public struct WrapHStack<Item, Content>: View where Content : View {
  @usableFromInline var items: [Item]
  @usableFromInline var content: (Item) -> Content
  @State private var height: CGFloat = 0
  
  public init(items: [Item], content: @escaping (Item) -> Content) {
    self.items = items
    self.content = content
  }
  
  public var body: some View {
    GeometryReader { geometry in
      self.generateContent(in: geometry)
        .anchorPreference(
          key: SizePref.self,
          value: .bounds,
          transform: {
            geometry[$0].size
          }
        )
    }
    .frame(height: height)
    .onPreferenceChange(SizePref.self, perform: {
      self.height = $0.height
    })
    
  }
  
  private func generateContent(in g: GeometryProxy) -> some View {
    var width = CGFloat.zero
    var totalHeight = CGFloat.zero
    
    return ZStack(alignment: .topLeading) {
      ForEach(Array(zip(self.items,self.items.indices)), id: \.1) { item in
        content(item.0)
          .padding([.all], 4)
          .alignmentGuide(.leading, computeValue: { d in
            if (abs(width - d.width) > g.size.width) {
              width = 0
              totalHeight -= d.height
            }
            let result = width
            width = item.1 == self.items.count - 1 ? 0 : width - d.width
            return result
          })
          .alignmentGuide(.top, computeValue: { d in
            let result = totalHeight
            if item.1 == self.items.count - 1 {
              totalHeight = 0
            }
            return result
          })
      }
    }
  }
}
