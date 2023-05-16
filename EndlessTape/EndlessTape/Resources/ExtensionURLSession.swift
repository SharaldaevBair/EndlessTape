import Foundation

//Работа с сетевым запросом
extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        
        let task = dataTask(with: request, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let response = response as? HTTPURLResponse,
                   response.statusCode < 200 || response.statusCode > 299 {
                    completion(.failure(NetworkError.codeError))
                    return
                }
                guard let data = data else { return }
                
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(NetworkError.codeError))
                }
            }
        })
        return task
    }
    
    enum NetworkError: Error {
        case codeError
    }
}
