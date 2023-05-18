import Foundation

final class ProfileService {

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private let decoder = JSONDecoder()
    private(set) var profile: Profile?
    static let shared = ProfileService()
    private var lastCode: String?

    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        if lastCode == token { return }
        task?.cancel()
        lastCode = token
        
        let request = makeRequest(token)
        
        let session = URLSession.shared
        let task = session.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let responseBody):
                self.profile = Profile(result: responseBody)
                guard let profile = self.profile else {return}
                completion(.success(profile))
                self.profile = profile
                self.task = nil
            case .failure(let error):
                completion(.failure(error))
                self.lastCode = nil
            }
        }
        self.task = task
        task.resume()
    }
}

extension ProfileService {
    private func makeRequest(_ token: String) -> URLRequest {
        var urlComponents = URLComponents(string: Constants.defaultBaseURL)
        urlComponents?.path = "/me"
        guard let url = urlComponents?.url else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
