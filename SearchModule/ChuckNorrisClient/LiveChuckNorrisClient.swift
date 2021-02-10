import ComposableArchitecture
import Combine

struct SearchResponse: Decodable {
  var result: [Fact]
}

extension ChuckNorrisClient {
  public static var live = ChuckNorrisClient(
    search: { query in
      var components = URLComponents(string: "https://api.chucknorris.io/jokes/search")!
      components.queryItems = [URLQueryItem(name: "query", value: query)]
      
      let x: Effect<[Fact], Failure> = URLSession.shared.dataTaskPublisher(for: components.url!)
        .map { data, _ in data }
        .decode(type: SearchResponse.self, decoder: jsonDecoder)
        .mapError { _ in Failure.invalidResponse }
        .map { $0.result }
        .eraseToEffect()
        
      
      return x
    },
    random: { category in
      var components = URLComponents(string: "https://api.chucknorris.io/jokes/random")!
      components.queryItems = [URLQueryItem(name: "category", value: category)]
      
      return URLSession.shared.dataTaskPublisher(for: components.url!)
        .map { data, _ in data }
        .decode(type: Fact.self, decoder: jsonDecoder)
        .mapError { _ in Failure.invalidResponse }
        .eraseToEffect()
    }
  )
}

private let jsonDecoder: JSONDecoder = {
  let d = JSONDecoder()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  formatter.calendar = Calendar(identifier: .iso8601)
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  d.dateDecodingStrategy = .formatted(formatter)
  return d
}()