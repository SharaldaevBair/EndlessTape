import UIKit

///Определяем структуру OAuthTokenResponseBody, которая будет использоваться для декодирования ответа сервера.
struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    ///Определяем свойства структуры, которые соответствуют полям ответа сервера.
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}

final class OAuth2Services {
    static let sharedServices = OAuth2Services()//Создание экземпляра класса OAuth2Services в виде синглтона (Singleton), что означает, что всегда будет существовать только один экземпляр этого класса в приложении.
    private init() {}
    
    private let urlSession = URLSession.shared //Создание экземпляра класса URLSession для выполнения HTTP-запросов. Этот экземпляр создается один раз при создании объекта OAuth2Services.
    
    private var task: URLSessionTask? //Переменная для хранения указателя на последнюю созданную задачу. Если активных задач нет, то значение будет nil
    
    private var lastCode: String? //Переменная для хранения значения code, которое было передано в последнем созданном запросе
    
    private let tokenStorage = OAuth2TokenStorage.sharedTokenStorage
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
            URLQueryItem(name: "client_id", value: UnsplashCredentials.accessKey),
            URLQueryItem(name: "client_secret", value: UnsplashCredentials.secretKey),
            URLQueryItem(name: "redirect_uri", value: UnsplashCredentials.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
//MARK: - Расширение для класса OAuth2Services
extension OAuth2Services {
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
//MARK: - HTTP Request
extension URLRequest {
    static func makeHTTPRequest( path: String,
                                 httpMethod: String,
                                 baseURL: URL = URL(string: "https://unsplash.com")!) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = httpMethod
        return request
    }
}
//MARK: - Network Connection
///Работаем с сетевым запросом
///Перечисление NetworkError, которое может быть использовано для указания ошибок, связанных с сетевыми запросами. В частности, NetworkError может быть связано с ошибками HTTP-запросов (например, неправильный код состояния HTTP), ошибками в URL-запросе или ошибками в URL-сессии.
private enum NetworkError: Error {
    case urlRequestError(Error)
    case urlSessionError
    case httpStatusCode(Int)
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnMainThread: (Result<T, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, let response = response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let result = try decoder.decode(T.self, from: data)
                        fulfillCompletionOnMainThread(.success(result))
                    } catch {
                        fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
                    }
                } else {
                    fulfillCompletionOnMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
            }
        })
        return task
    }
}

