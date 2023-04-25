import UIKit

struct OAuthTokenResponseBody: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}

final class OAuth2Service {
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else { return }
        let clientId = "YOUR_CLIENT_ID"
        let clientSecret = "YOUR_CLIENT_SECRET"
        let redirectUri = "YOUR_REDIRECT_URI"
        let grantType = "authorization_code"
        
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri,
            "code": code,
            "grant_type": grantType
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let responseBody = try? JSONDecoder().decode(OAuthTokenResponseBody.self, from: data) {
                    let token = responseBody.accessToken
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "Unable to decode response body", code: 0, userInfo: nil)))
                }
            } else {
                completion(.failure(NSError(domain: "HTTP error", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: nil)))
            }
        }
        
        task.resume()
    }
}
