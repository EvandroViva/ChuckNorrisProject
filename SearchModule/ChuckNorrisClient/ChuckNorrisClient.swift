import ComposableArchitecture

// MARK: - API models

public struct Fact: Codable, Equatable {
  public var icon_url: String
  public var id: String
  public var url: String
  public var value: String
  public var categories: [String]
  
  public init(icon_url: String, id: String, url: String, value: String, categories: [String]) {
    self.icon_url = icon_url
    self.id = id
    self.url = url
    self.value = value
    self.categories = categories
  }
}

// MARK: - API client interface

public struct ChuckNorrisClient {
  public var search: (String) -> Effect<[Fact], Failure>
  public var random: (String) -> Effect<Fact, Failure>
  public var categories: () -> Effect<[String], Failure>
  
  public enum Failure: Error, Equatable {
    case invalidResponse, rateLimitted, serverBusy, casting, unknown
  }

}
