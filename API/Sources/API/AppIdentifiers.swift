import Foundation

public enum AppIdentifiers {
  private static func infoString(_ key: String) -> String {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
      !value.isEmpty,
      !value.contains("$(")
    else {
      fatalError("Missing Info.plist value for \(key). Ensure OrgIdentifier is set in your target's Info.plist.")
    }
    return value
  }

  public static var orgIdentifier: String { infoString("OrgIdentifier") }

  public static var appGroup: String { infoString("AppGroupIdentifier") }

  public static var keychainService: String { "\(orgIdentifier).AudioBS" }

  public static var closeSessionTaskIdentifier: String { "\(orgIdentifier).AudioBS.close-session" }

  public static var downloadTaskPrefix: String { "\(orgIdentifier).AudioBS.download." }

  public static var watchDownloadTaskPrefix: String { "\(orgIdentifier).AudioBS.watch.download." }
}

public extension UserDefaults {
  static var appGroup: UserDefaults {
    guard let defaults = UserDefaults(suiteName: AppIdentifiers.appGroup) else {
      fatalError("App group UserDefaults unavailable for \(AppIdentifiers.appGroup)")
    }
    return defaults
  }
}
