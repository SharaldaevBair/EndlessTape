import Foundation

final class ProfileImageService {
    private var task: URLSessionTask?
    private var lastUsername: String?
    static let shared = ProfileImageService()
    private (set) var avatarURL: String?
    private let objectTask = URLSession.shared
    private var lastToken: String?
    static let DidChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    func fetchProfileImageURL(username: String, token: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        if lastToken == token { return }
        if lastUsername == username { return }
        task?.cancel()
        lastToken = token
        lastUsername = username

        let request = requestProfileImage(username: username, token: token)

        let urlSession = URLSession.shared
        let task = urlSession.objectTask(for: request) { (result: Result<UserResult, Error>) in
            switch result {
            case .success(let responseBody):
                let profileImageURL = responseBody.profileImage.small
                self.avatarURL = profileImageURL
                completion(.success(profileImageURL))
                NotificationCenter.default
                    .post(
                        name: ProfileImageService.DidChangeNotification,
                        object: self,
                        userInfo: ["URL": profileImageURL])

                self.task = nil
            case .failure(let error):
                completion(.failure(error))
                self.lastUsername = nil
            }
        }
        self.task = task
        task.resume()
    }

    private func requestProfileImage(username: String, token: String) -> URLRequest {
        let unsplashGetProfileImageURLString = Constants.defaultBaseURL + "users/" + username
        guard let url = URL(string: unsplashGetProfileImageURLString)
            else { fatalError("Failed to create URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("создан запрос на получение аватара \(request) с токеном \(token)")
        return request
    }
}
