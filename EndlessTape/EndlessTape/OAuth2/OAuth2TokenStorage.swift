import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage { //Cоздаем класс OAuth2TokenStorage и определяем его как синглтон с помощью статической переменной sharedTokenStorage.

    static let shared = OAuth2TokenStorage()
    private let keyChainStorage = KeychainWrapper.standard

    var token: String? {
        get {
            keyChainStorage.string(forKey: .tokenKey)
        }
        set {
            if let token = newValue {
                keyChainStorage.set(token, forKey: .tokenKey)
            } else {
                keyChainStorage.removeObject(forKey: .tokenKey)
            }
        }
    }
}

extension String {
    static let tokenKey = "bearerToken" //Также создаем константу tokenKey для определения ключа, используемого для сохранения токена в User Defaults.
}
