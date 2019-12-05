//
//  ImageCache.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import UIKit

struct ImageCache {
    fileprivate var cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 15
    }

    func add(url: String, image: UIImage) {
        cache.setObject(image, forKey: url as NSString)
    }

    func get(url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }

    func invalidate() {
        cache.removeAllObjects()
    }
}
