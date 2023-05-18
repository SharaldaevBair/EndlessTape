import UIKit

final class OAuth2Service {
    static let shared = OAuth2Service()//Создание экземпляра класса OAuth2Services в виде синглтона (Singleton), что означает, что всегда будет существовать только один экземпляр этого класса в приложении.
    private let urlSession = URLSession.shared //Создание экземпляра класса URLSession для выполнения HTTP-запросов. Этот экземпляр создается один раз при создании объекта OAuth2Services.
    private var task: URLSessionTask?//Переменная для хранения указателя на последнюю созданную задачу. Если активных задач нет, то значение будет nil
    private var lastCode: String?//Переменная для хранения значения code, которое было передано в последнем созданном запросе
    private let tokenStorage = OAuth2TokenStorage()
    private (set)  var authToken: String? { //свойство authToken для хранения токена аутентификации
        get {
            return tokenStorage.token
        }
        set {
            tokenStorage.token = newValue
        }
    }

    //Объявление метода fetchAuthToken для выполнения запроса на получение токена аутентификации.
    func fetchAuthToken(_ code: String, completion: @escaping(Result<String, Error>) -> Void ) {        assert(Thread.isMainThread)//Проверяем, что код выполняется из главного потока. Для корректности вычислений существенно, чтобы обращение к task и lastCode было из главного потока, иначе случится гонка.
        
        if lastCode == code {return}// Если lastCode != code, то мы должны всё-таки сделать новый запрос.
        task?.cancel()//Старый запрос нужно отменить, но если task == nil, то ничего не будет выполнено, и мы просто пройдём дальше вниз.

        lastCode = code //Запомнили code, использованный в запросе.
        
        guard let request = authTokenRequest(code: code) else { fatalError("Problems with authToken request")}//Создаём запрос на получение Auth Token с заданным кодом.
        let task = object(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    completion(.success(authToken))//в случае успеха, токен аутентификации извлекается из ответа на запрос и сохраняется в OAuth2TokenStorage и в свойстве authToken
                    self.task = nil // Если запрос завершился с ошибкой, удалим lastCode, чтобы можно было повторить запрос с тем же кодом.
                case .failure(let error):
                    completion(.failure(error))
                    self.lastCode = nil
                }
            }
        }
            self.task = task //Прежде чем запускать выполнение запроса, нужно зафиксировать состояние, сохранив указатель на task, иначе возможны гонки.
            task.resume() //Запускаем запрос на выполнение.
    }
}

extension OAuth2Service {
    private func object(for request: URLRequest, completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void) -> URLSessionTask {
        let decoder = JSONDecoder()
        return urlSession.data(for: request) { (result: Result<Data, Error>) in
            let response = result.flatMap {data -> Result<OAuthTokenResponseBody, Error> in
                Result { try decoder.decode(OAuthTokenResponseBody.self, from: data) }
            }
            completion(response)
        }
    }
    ///Определяем функцию authTokenRequest(code:), которая возвращает URLRequest.
    ///
    ///Вызываем метод makeHTTPRequest на классе URLRequest, передавая значения пути, метода, и базового URL, а также некоторых параметров, которые требуются для запроса токена аутентификации.
    private func authTokenRequest(code: String) -> URLRequest? {
        URLRequest.makeHTTPRequest(
            path: "/oauth/token"
            + "?client_id=\(Constants.accessKey)"
            + "&&client_secret=\(Constants.secretKey)"
            + "&&redirect_uri=\(Constants.redirectURI)"
            + "&&code=\(code)"
            + "&&grant_type=authorization_code",
            httpMethod: "POST", baseURL:
            Constants.baseURLString
        )
    }
}

extension URLSession {
    func data(for request: URLRequest,
              completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask  {
        ///Эта часть кода определяет замыкание fulfillCompletion, которое будет вызываться внутри метода dataTask после завершения запроса. В замыкании определен асинхронный вызов completion на главной очереди, передавая результат в качестве аргумента.
        let fulfillCompletion: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        ///Здесь определяется задача task с использованием метода dataTask(with:completionHandler:). При завершении запроса вызывается замыкание completionHandler, которое принимает параметры data, response и error.
        ///
        ///Если data, response и statusCode определены и код состояния находится в диапазоне 200-299, то вызывается замыкание fulfillCompletion с результатом в виде .success(data).
        let task = dataTask(with: request, completionHandler: {data, response, error in
            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode
            {
                if 200..<300 ~= statusCode {
                    fulfillCompletion(.success(data))
                } else {
                    fulfillCompletion(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletion(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletion(.failure(NetworkError.urlSessionError))
            }
        })
        task.resume()
        return task
    }
}
