import UIKit

final class OAuth2TokenStorage {
    
    private let userDefaults = UserDefaults.standard
    
    var token: String? {
        get {
            return userDefaults.string(forKey: "BearerToken")
        }
        set {
            userDefaults.set(newValue, forKey: "BearerToken")
        }
    }
}

