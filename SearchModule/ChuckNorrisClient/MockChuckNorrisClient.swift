import ComposableArchitecture

extension ChuckNorrisClient {
  
  public static func mock(
    search: @escaping (String) -> Effect<[Fact], Failure> = { _ in fatalError() },
    random: @escaping (String) -> Effect<Fact, Failure> = { _ in fatalError() }) -> Self {
    return Self(
      search: search,
      random: random
    )
  }
}
