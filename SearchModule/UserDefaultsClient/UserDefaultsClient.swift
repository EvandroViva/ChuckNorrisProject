import ComposableArchitecture

public struct UserDefaultsClient {
  public var load: (String) -> Effect<[String], Never>
  public var save: (String, [String]) -> Effect<Never, Never>
  public var loadData: (String) -> Effect<Data?, Never>
  public var saveData: (String, Data) -> Effect<Never, Never>
  
}
