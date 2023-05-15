import UIKit

extension URLRequest {
    static func makeHTTPRequest( path: String,
                                 httpMethod: String,
                                 baseURL: URL = URL(string: "https://unsplash.com")!) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = httpMethod
        return request
    }
}
