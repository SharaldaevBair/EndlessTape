import UIKit

final class ProfileImageService {
    
    static let DidChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    static var shared = ProfileImageService()
    let tokenStorage = OAuth2TokenStorage()
    
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    
    private (set) var avatarURL: String?
    
    private init() {}
    
    enum ProfileImageError: Error {
        case unauthorized
        case invalidData
        case decodingFailed
    }

    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = tokenStorage.token else {return}
        
        let urlString = "https://api.unsplash.com/users/\(username)"
        guard let url = URL(string: urlString) else { return}
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let dataTask = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            switch result {
            case .success(let userResult):
                self?.avatarURL = userResult.profileImage.small
                if let avatarURL = self?.avatarURL {
                    completion(.success(userResult.profileImage.small))
                    NotificationCenter.default.post(name: ProfileImageService.DidChangeNotification,
                                                      object: self,
                                                      userInfo:  ["URL": userResult.profileImage.small])
                } else {
                    completion(.failure(ProfileImageError.invalidData))
                }
                self?.task = nil
            case .failure(_):
                completion(.failure(ProfileImageError.decodingFailed))
            }
        }
        task = dataTask
        task?.resume()
    }
}
