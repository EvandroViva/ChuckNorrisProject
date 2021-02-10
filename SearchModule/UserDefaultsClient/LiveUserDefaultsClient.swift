import ComposableArchitecture


extension UserDefaultsClient {
  public static var live = UserDefaultsClient(
    load: { key in
      return .result { () -> Result<[String], Never> in
        let data = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        return .success(data)
      }
    },
    save: { key, data in
      .fireAndForget {
        UserDefaults.standard.set(data, forKey: key)
      }
    })
}
