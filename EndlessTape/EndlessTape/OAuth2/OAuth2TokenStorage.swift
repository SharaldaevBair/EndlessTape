import UIKit

final class OAuth2TokenStorage {
    //Cоздаем класс OAuth2TokenStorage и определяем его как синглтон с помощью статической переменной sharedTokenStorage.
    static let sharedTokenStorage = OAuth2TokenStorage()
    //Также создаем константу tokenKey для определения ключа, используемого для сохранения токена в User Defaults.
    private let tokenKey = "BearerToken"
    //  Вычислимое свойство token определяет переопределенные геттер и сеттер. Геттер возвращает значение из User Defaults, используя ключ "BearerToken". Сеттер сохраняет значение в User Defaults, также используя этот ключ.
    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
    //  Инициализатор класса (init) определен как приватный, чтобы предотвратить создание объектов класса за пределами класса. Таким образом, объекты класса можно создавать только через статическую переменную shared.
    private init() {}
}
