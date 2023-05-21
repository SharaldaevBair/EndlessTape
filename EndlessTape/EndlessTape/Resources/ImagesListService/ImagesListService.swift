//
//  ImagesListService.swift
//  EndlessTape
//
//  Created by Баир Шаралдаев on 21.05.2023.
//

import Foundation
final class ImagesListService { //Для получения данных из сети 
    static let shared = ImagesListService()
    private (set) var photos: [Photo] = [] //хранения последовательности всех загруженных из сети фотографий
    private var lastLoadedPage: Int? //номер последней скачанной страницы
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private let dateFormatter = ISO8601DateFormatter()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    func fetchPhotosNextPage() { //получениe очередной страницы
        guard task == nil else { return }
        
        let nextPage = lastLoadedPage == nil ? 1 : lastLoadedPage! + 1
        lastLoadedPage = (lastLoadedPage ?? 0) + 1
        
        assert(Thread.isMainThread)
        task?.cancel()
        
        guard var request = makeRequest(path: "/photos?page=\(nextPage)&&per_page=10") else {
            return assertionFailure("Error photo request")
        }
        
        request.httpMethod = "GET"
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let photoResult):
                photoResult.forEach { photoResult in
                    let photo = Photo(
                        id: photoResult.id,
                        size: CGSize(width: photoResult.width, height: photoResult.height),
                        createdAt: self.dateFormatter.date(from: photoResult.createdAt ?? ""),
                        welcomeDescription: photoResult.description,
                        thumbImageURL: photoResult.urls.thumb,
                        fullImageURL: photoResult.urls.full,
                        isLiked: photoResult.likedByUser)
                    self.photos.append(photo)
                }
                
                NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self, userInfo: ["photos": self.photos])
            case .failure(let error):
                print(error)
            }
            self.task = nil
        }
        
        self.task = task
        task.resume()
        
        if lastLoadedPage == nil {
            lastLoadedPage = 1
        } else {
            lastLoadedPage? += 1
        }
    }
    
    private func makeRequest(path: String) -> URLRequest? {
        guard let baseURL = URL(string: Constants.defaultBaseURL) else {
            assertionFailure("url is nil")
            return nil
        }
        
        var request = URLRequest(url: baseURL)
        guard let token = OAuth2TokenStorage().token else {
            assertionFailure("token is nil")
            return nil
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
