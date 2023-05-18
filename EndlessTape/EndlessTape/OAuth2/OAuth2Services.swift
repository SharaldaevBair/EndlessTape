import UIKit

final class OAuth2Service {
    static let shared = OAuth2Service()//Создание экземпляра класса OAuth2Services в виде синглтона (Singleton), что означает, что всегда будет существовать только один экземпляр этого класса в приложении.

    private let urlSession = URLSession.shared //Создание экземпляра класса URLSession для выполнения HTTP-запросов. Этот экземпляр создается один раз при создании объекта OAuth2Services.

    private var taskURL: URLSessionTask? //Переменная для хранения указателя на последнюю созданную задачу. Если активных задач нет, то значение будет nil

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
    func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread) //Проверяем, что код выполняется из главного потока. Для корректности вычислений существенно, чтобы обращение к task и lastCode было из главного потока, иначе случится гонка.
        guard lastCode == code else { return } // Если lastCode != code, то мы должны всё-таки сделать новый запрос.
        taskURL?.cancel() //Старый запрос нужно отменить, но если task == nil, то ничего не будет выполнено, и мы просто пройдём дальше вниз.
        lastCode = code //Запомнили code, использованный в запросе.
        
        guard let urlRequest = authTokenRequest(code: code) else {
            fatalError("Problems with authToken request") //Создаём запрос на получение Auth Token с заданным кодом.
        }
        
        let task = urlSession.objectTask(for: urlRequest) {(result: Result<OAuthTokenResponseBody, Error>) in
            switch result {
            case .success(let object):
                let authToken = object.accessToken
                self.authToken = authToken
                completion(.success(authToken)) //в случае успеха, токен аутентификации извлекается из ответа на запрос и сохраняется в OAuth2TokenStorage и в свойстве authToken
            case .failure(let error):
                completion(.failure(error))
                self.lastCode = nil
            }
            self.taskURL = nil // Если запрос завершился с ошибкой, удалим lastCode, чтобы можно было повторить запрос с тем же кодом.
        }
        self.taskURL = task //Прежде чем запускать выполнение запроса, нужно зафиксировать состояние, сохранив указатель на task, иначе возможны гонки.
        task.resume() //Запускаем запрос на выполнение.
        
    }

    private func authTokenRequest(code: String) -> URLRequest? {
        URLRequest.makeHTTPRequest(
            path: "/oauth/token"
            + "?client_id=\(Constants.accessKey)"
            + "&&client_secret=\(Constants.secretKey)"
            + "&&redirect_uri=\(Constants.redirectURI)"
            + "&&code=\(code)"
            + "&&grant_type=authorization_code",
            httpMethod: "POST",
            baseURL: Constants.baseURLString
        )
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
