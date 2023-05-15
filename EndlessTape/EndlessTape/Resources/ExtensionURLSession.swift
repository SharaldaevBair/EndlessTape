import Foundation

///Работаем с сетевым запросом
///Перечисление NetworkError, которое может быть использовано для указания ошибок, связанных с сетевыми запросами. В частности, NetworkError может быть связано с ошибками HTTP-запросов (например, неправильный код состояния HTTP), ошибками в URL-запросе или ошибками в URL-сессии.

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}

extension URLSession {
    
    func objectTask<T: Decodable>(for request: URLRequest, completion: @escaping (Result<T, Error>) -> Void)
    -> URLSessionTask {
        
        let fulfillCompletion: (Result<T, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request) { data, response, error in
            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode {
                
                if 200 ..< 300 ~= statusCode {
//                    do {
//                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                        print(json)
//                    } catch {
//                        print("Failed to parse")
//                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(T.self, from: data)
                        fulfillCompletion(.success(result))
                    } catch {
                        fulfillCompletion(.failure(NetworkError.urlRequestError(error)))
                    }
                } else {
                    fulfillCompletion(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletion(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletion(.failure(NetworkError.urlSessionError))
            }
        }
        return task
    }
}
