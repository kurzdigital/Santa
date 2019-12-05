//
//  Links.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import Foundation

struct Links: Codable, Equatable {
    let image: String?
    let data: String?

    init(image: String? = nil, data: String? = nil) {
        self.image = image
        self.data = data
    }
}
