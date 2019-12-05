//
//  Products.swift
//  Santa_Example
//
//  Created by Christian Braun on 05.12.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

struct Product: Codable {
    let name: String
}

struct Products: Codable {
    let products: [Product]
}
