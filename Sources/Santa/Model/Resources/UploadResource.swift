//
//  File.swift
//  
//
//  Created by Christian Braun on 02.05.22.
//

import Foundation

public final class UploadResource: Resource {
    public let url: String
    public let method: HTTPMethod
    public var body: Data? {
        try? Data(contentsOf: filePath)
    }
    public let filePath: URL
    public var authorizationNeeded = true
    public var headers = Headers()
    public let uuid: UUID

    public init(
        url: String,
        method: HTTPMethod,
        filePath: URL,
        uuid: UUID = UUID(),
        authorizationNeeded: Bool = true) {
        self.url = url
        self.method = method
        self.filePath = filePath
        self.uuid = uuid
        self.authorizationNeeded = authorizationNeeded
    }

    public func update(uuid: UUID) -> UploadResource {
        return UploadResource(
            url: url,
            method: method,
            filePath: filePath,
            uuid: uuid,
            authorizationNeeded: authorizationNeeded)
    }
}
