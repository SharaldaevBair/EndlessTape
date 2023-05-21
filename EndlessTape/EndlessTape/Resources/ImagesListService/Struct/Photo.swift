//
//  structPhoto.swift
//  EndlessTape
//
//  Created by Баир Шаралдаев on 21.05.2023.
//

import Foundation
struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let fullImageURL: String
    let isLiked: Bool
}

