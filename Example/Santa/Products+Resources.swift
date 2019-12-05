//
//  Products+Resources.swift
//  Santa_Example
//
//  Created by Christian Braun on 05.12.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Santa

private let url = "https://api.predic8.de/shop/products/"

extension Products {
    static var all: DataResource<Products> {
        let resource = DataResource(url: url, method: .get, body: nil) { data in
            return try JSONDecoder().decode(Products.self, from: data)
        }
        resource.authorizationNeeded = false
        return resource
    }

    static var allAsDownload: DownloadResource {
        return DownloadResource(url: url, method: .get, body: nil, fileName: "Products.txt", uuid: UUID(), authorizationNeeded: false)
    }
}
