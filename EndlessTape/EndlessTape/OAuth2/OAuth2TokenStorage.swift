import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage { //Cоздаем класс OAuth2TokenStorage и определяем его как синглтон с помощью статической переменной sharedTokenStorage.
    
    static let sharedTokenStorage = OAuth2TokenStorage()
    private let keyChainStorage = KeychainWrapper.standard
    //  Вычислимое свойство token определяет переопределенные геттер и сеттер. Геттер возвращает значение из User Defaults, используя ключ "BearerToken". Сеттер сохраняет значение в User Defaults, также используя этот ключ.
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

