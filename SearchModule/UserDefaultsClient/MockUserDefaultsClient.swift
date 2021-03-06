import ComposableArchitecture

extension UserDefaultsClient {
  
  public static func mock(
    load: @escaping (String) -> Effect<[String], Never> = { _ in fatalError() },
    save: @escaping (String, [String]) -> Effect<Never, Never> = { _,_  in fatalError() },
    loadData: @escaping (String) -> Effect<Data?, Never> = { _ in fatalError() },
    saveData: @escaping (String, Data) -> Effect<Never, Never> = { _,_  in fatalError() }) -> Self {
    return Self(
      load: load,
      save: save,
      loadData: loadData,
      saveData: saveData
    )
  }
}
