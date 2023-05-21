//
//  PhotoResult.swift
//  EndlessTape
//
//  Created by Баир Шаралдаев on 21.05.2023.
//

import Foundation
struct PhotoResult: Decodable { //структура для декодинга JSON-ответа от Unsplash
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case likedByUser = "liked_by_user"
        case id, width, height, description, urls
    }
}
