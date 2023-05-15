import UIKit

final class OAuth2Service {
    static let shared = OAuth2Service()//Создание экземпляра класса OAuth2Services в виде синглтона (Singleton), что означает, что всегда будет существовать только один экземпляр этого класса в приложении.

    private let urlSession = URLSession.shared //Создание экземпляра класса URLSession для выполнения HTTP-запросов. Этот экземпляр создается один раз при создании объекта OAuth2Services.

    private var task: URLSessionTask? //Переменная для хранения указателя на последнюю созданную задачу. Если активных задач нет, то значение будет nil

    private var lastCode: String? //Переменная для хранения значения code, которое было передано в последнем созданном запросе

    private let tokenStorage = OAuth2TokenStorage.shared
    private (set)  var authToken: String? {//свойство authToken для хранения токена аутентификации
        get {
            return tokenStorage.token
        }
        set {
            tokenStorage.token = newValue
        }
    }

    ///Объявление метода fetchAuthToken для выполнения запроса на получение токена аутентификации.
    func fetchOAuthToken(_ code: String, completion: @escaping(Result<String, Error>) -> Void ) {
        assert(Thread.isMainThread) //Проверяем, что код выполняется из главного потока. Для корректности вычислений существенно, чтобы обращение к task и lastCode было из главного потока, иначе случится гонка.

        if lastCode == code { return } // Если lastCode != code, то мы должны всё-таки сделать новый запрос.

        task?.cancel() //Старый запрос нужно отменить, но если task == nil, то ничего не будет выполнено, и мы просто пройдём дальше вниз.

        lastCode = code //Запомнили code, использованный в запросе.
        let request = authTokenRequest(code: code) //Создаём запрос на получение Auth Token с заданным кодом.

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return } //обработка результата сетевого вызова с вызовом completion
            switch result {
            case .success(let decodedData):
                completion(.success(decodedData.accessToken))//в случае успеха, токен аутентификации извлекается из ответа на запрос и сохраняется в OAuth2TokenStorage и в свойстве authToken
                self.task = nil //Обнуляем task, ведь мы завершили обработку. Иногда бывает важно сделать обнуление строго после вызова completion. В противном случае возможны гонки.
            case .failure(let error):
                completion(.failure(error))
                self.lastCode = nil // Если запрос завершился с ошибкой, удалим lastCode, чтобы можно было повторить запрос с тем же кодом.
            }
        }
        self.task = task //Прежде чем запускать выполнение запроса, нужно зафиксировать состояние, сохранив указатель на task, иначе возможны гонки.
        task.resume() //Запускаем запрос на выполнение.
    }

    ///Определяем функцию authTokenRequest(code:), которая возвращает URLRequest. Вызываем метод makeHTTPRequest на классе URLRequest, передавая значения пути, метода, и базового URL, а также некоторых параметров, которые требуются для запроса токена аутентификации.
    private func authTokenRequest(code: String) -> URLRequest {
        let unsplashAuthorizePostURLString = "https://unsplash.com/oauth/token"
        var urlComponents = URLComponents(string: unsplashAuthorizePostURLString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = urlComponents.url else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
extension OAuth2Service {
    ///Функция, которая создает задачу URLSessionTask для выполнения запроса и получения данных. Она использует переданный URLRequest и обработчик завершения для создания URLSessionDataTask, который выполняет запрос и возвращает ответ. Если запрос был выполнен успешно, данные из ответа декодируются в экземпляр структуры OAuthTokenResponseBody, и успешный результат передается в обработчик завершения. Если произошла ошибка, она передается в обработчик завершения.
    private func object( for request: URLRequest, completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void) -> URLSessionTask {
        let decoder = JSONDecoder()
        return urlSession.objectTask(for: request) { (result: Result<Data, Error>) in
            let response = result.flatMap {data -> Result<OAuthTokenResponseBody, Error> in
                //Определяем константу response, используя flatMap для извлечения данных из результата выполнения запроса. Мы затем используем декодер JSON для декодирования ответа сервера в экземпляр структуры OAuthTokenResponseBody. Мы завершаем задачу, вызывая обработчик завершения completion, передавая результат выполнения запроса в виде объекта Result.
                Result { try decoder.decode(OAuthTokenResponseBody.self, from: data) }
            }
            completion(response)
        }
    }
}
