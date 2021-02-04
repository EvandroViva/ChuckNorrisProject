import Foundation

public extension Array {
  func withIndex() -> [(Int, Element)] {
    return self.enumerated().map { return ($0.offset, $0.element) }
  }
}
