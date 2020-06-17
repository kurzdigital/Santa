//
//  DataResource.swift
//  Pods-kta-taxstamp-montenegro
//
//  Created by Christian Braun on 17.06.20.
//

import Foundation

public typealias Boundary = String

public final class DataResource<A>: Resource {
    public let url: String
    public let method: HTTPMethod
    public let body: Data?
    public let parseData: (Data) throws -> A?
    public var authorizationNeeded = true
    public var headers = Headers()
    public let uuid: UUID

    public init(
        url: String,
        method: HTTPMethod,
        body: Data? = nil,
        uuid: UUID = UUID(),
        authorizationNeeded: Bool = true,
        parseData:@escaping (Data) throws -> A?) {
        self.url = url
        self.method = method
        self.body = body
        self.parseData = parseData
        self.uuid = uuid
        self.authorizationNeeded = authorizationNeeded
    }

    public func update(uuid: UUID) -> DataResource {
        return DataResource(
            url: url,
            method: method,
            body: body,
            uuid: uuid,
            authorizationNeeded: authorizationNeeded,
            parseData: parseData)
    }

    public static func randomBoundary() -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return "XXX\(String(alphabet.shuffled()).dropFirst(alphabet.count - 10))XXX"
    }

    public static func multipartFormData(with data: Data, boundary: Boundary, mimeType: String) -> Data {
        var returnData = Data()

        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
            let contentType = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8),
            let contentDisposition = "Content-Disposition:form-data; name=\"file\"; filename=\"data.jpg\"\r\n".data(using: .utf8),
            let newLine = "\r\n".data(using: .utf8),
            let closingBoundary = "--\(boundary)--".data(using: .utf8) else {
                preconditionFailure("Unable to create multi part form data")
        }

        returnData.append(boundaryData)
        returnData.append(contentDisposition)
        returnData.append(contentType)
        returnData.append(data)
        returnData.append(newLine)
        returnData.append(closingBoundary)

        return returnData
    }
}

extension DataResource where A: Decodable {
    public convenience init(url: String, method: HTTPMethod, body: Data? = nil, uuid: UUID = UUID(), authorizationNeeded: Bool = true) {
        self.init(url: url, method: method, body: body, uuid: uuid, authorizationNeeded: authorizationNeeded) { data -> A in
            try JSONDecoder().decode(A.self, from: data)
        }
    }
}
