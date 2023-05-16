import UIKit

import Foundation

extension URLRequest {
    static func makeHTTPRequest(path: String, httpMethod: String, baseURL: String) -> URLRequest? {
        guard
            let url = URL(string: baseURL),
            let baseUrl = URL(string: path, relativeTo: url)
        else { return nil }

        var request = URLRequest(url: baseUrl)
        request.httpMethod = httpMethod

        if baseURL == Constants.defaultApiBaseURLString {
            guard let authToken = OAuth2TokenStorage.shared.token else { return nil }
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
