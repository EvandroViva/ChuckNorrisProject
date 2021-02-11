import ComposableArchitecture

public struct UserDefaultsClient {
  var load: (String) -> Effect<[String], Never>
  var save: (String, [String]) -> Effect<Never, Never>
  var loadData: (String) -> Effect<Data?, Never>
  var saveData: (String, Data) -> Effect<Never, Never>
  
}
