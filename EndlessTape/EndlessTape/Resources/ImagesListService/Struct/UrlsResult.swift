//
//  UrlsResult.swift
//  EndlessTape
//
//  Created by Баир Шаралдаев on 22.05.2023.
//

import Foundation
struct UrlsResult: Decodable { //вспомогательная структура для получения полей из "urls"
    let raw: String
    let full: String
    let regular: String
    let small : String
    let thumb: String
}
