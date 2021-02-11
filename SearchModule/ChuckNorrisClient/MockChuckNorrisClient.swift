import ComposableArchitecture

extension ChuckNorrisClient {
  
  public static func mock(
    search: @escaping (String) -> Effect<[Fact], Failure> = { _ in fatalError() },
    random: @escaping (String) -> Effect<Fact, Failure> = { _ in fatalError() },
    categories: @escaping () -> Effect<[String], Failure> = { fatalError() }) -> Self {
    return Self(
      search: search,
      random: random,
      categories: categories
    )
  }
}
