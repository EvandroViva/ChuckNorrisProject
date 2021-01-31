import ComposableArchitecture

public struct UserDefaultsClient {
  var load: (String) -> Effect<[String], Never>
  var save: (String, [String]) -> Effect<Never, Never>
  
}
