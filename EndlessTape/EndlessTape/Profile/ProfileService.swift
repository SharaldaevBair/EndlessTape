import Foundation

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String?
}

struct Profile: Decodable {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    
    init(from result: ProfileResult) {
        self.username = result.username
        self.name = "\(result.firstName) \(result.lastName)"
        self.loginName = "@\(username)"
        self.bio = result.bio
    }
}

final class ProfileService {
    private var task: URLSessionTask?
    private var lastToken: String?

    static let shared = ProfileService()
    private(set) var profile: Profile?
    
    func fetchProfile(_ token: String, completion: @escaping(Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        task?.cancel()
        
        var urlComponents = URLComponents(string: UnsplashCredentials.defaultBaseURL)
        urlComponents?.path = "/me"
        guard let url = urlComponents?.url else { fatalError("Failed to create URL") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let urlSession = URLSession.shared
        let task = urlSession.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let responseBody):
                self.profile = Profile(from: responseBody)
                guard let profile = self.profile else {return}
                completion(.success(profile))
                self.profile = profile
                self.task = nil
            case .failure(let error):
                completion(.failure(error))
                self.lastToken = nil
                
            }
        }
        self.task = task
        task.resume()
    }
}
