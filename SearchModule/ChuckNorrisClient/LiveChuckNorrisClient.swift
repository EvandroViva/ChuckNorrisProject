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
        .mapError({ $0 as Error })
        .map({ response -> AnyPublisher<[Fact], Error> in
          guard let httpResponse = response.response as? HTTPURLResponse else {
            return Fail(error: Failure.invalidResponse)
              .eraseToAnyPublisher()
          }
          if httpResponse.statusCode == 429 {
            return Fail(error: Failure.rateLimitted)
              .eraseToAnyPublisher()
          }
          if httpResponse.statusCode == 503 {
            return Fail(error: Failure.serverBusy)
              .eraseToAnyPublisher()
          }
          if httpResponse.statusCode != 200 {
            return Fail(error: Failure.unknown)
              .eraseToAnyPublisher()
          }
          
          return Just(response)
            .map { data, _ in data }
            .decode(type: SearchResponse.self, decoder: jsonDecoder)
            .map { $0.result }
            .mapError { _ in Failure.casting }
            .eraseToAnyPublisher()
        })
        .switchToLatest()
        .eraseToAnyPublisher()
        .mapError { $0 as? Failure ?? Failure.unknown }
        .retry(intervals: [.seconds(4), .seconds(8)], if: { $0 != .casting })
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
    },
    categories: {
      var components = URLComponents(string: "https://api.chucknorris.io/jokes/categories")!
      
      return URLSession.shared.dataTaskPublisher(for: components.url!)
        .map { data, _ in data }
        .decode(type: [String].self, decoder: jsonDecoder)
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

extension Publishers {
  struct RetryIf<P: Publisher>: Publisher {
    typealias Output = P.Output
    typealias Failure = P.Failure
    
    let publisher: P
    let intervals: [RunLoop.SchedulerTimeType.Stride]
    let condition: (P.Failure) -> Bool
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
      var intervals = self.intervals
      guard intervals.count > 0 else { return publisher.receive(subscriber: subscriber) }
      
      publisher
        .delay(for: intervals.removeFirst(), scheduler: RunLoop.main)
        .catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
          if condition(error)  {
            return RetryIf(publisher: publisher, intervals: intervals, condition: condition).eraseToAnyPublisher()
          } else {
            return Fail(error: error).eraseToAnyPublisher()
          }
        }
        .receive(subscriber: subscriber)
    }
  }
}

extension Publisher {
  func retry(intervals: [RunLoop.SchedulerTimeType.Stride], if condition: @escaping (Failure) -> Bool) -> Publishers.RetryIf<Self> {
    Publishers.RetryIf(publisher: self, intervals: intervals, condition: condition)
  }
}
