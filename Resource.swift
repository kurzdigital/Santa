//
//  Resource.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//
import Foundation

typealias Boundary = String

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

struct HTTPHeader {
    static let contentTypeNone = ""
    static let contentTypeTextPlain = "text/plain"
    static let contentTypeJson = "application/json"
    static let contentTypeUrlEncoded = "application/x-www-form-urlencoded"
    static let contentTypeImageJpeg = "image/jpeg"
    static let contentTypeImagePng = "image/png"
    static let acceptNone = ""
    static let acceptTextPlain = "text/plain"
    static let acceptJson = "application/json"
    static let acceptPdf = "application/pdf"

    static func contentTypeMultipart(boundary: String) -> String {
        return "multipart/form-data; boundary=\(boundary)"
    }
}

struct Headers {
    var contentType = HTTPHeader.contentTypeNone
    var accept = HTTPHeader.acceptNone
    var other = [String: String]()
}

protocol Resource {
    var url: String { get }
    var method: HTTPMethod { get }
    var body: Data? { get }
    var authorizationNeeded: Bool { get }
    var headers: Headers { get }
    var uuid: UUID { get }

    /// When we do authentication we want to give it the same uuid as the actual data request.
    /// The reason for this is, that canceling the actual data request must also cancel the current
    /// Auth request. As the auth and data request are strictly sequentiel we just pass the uuid for the
    /// data request to the auth request. When the auth request is done the uuid can be used for the
    /// data request.
    func update(uuid: UUID) -> Self
}

final class DataResource<A>: Resource {
    let url: String
    let method: HTTPMethod
    let body: Data?
    let parseData: (Data) throws -> A?
    var authorizationNeeded = true
    var headers = Headers()
    let uuid: UUID

    init(
        url: String,
        method: HTTPMethod,
        body: Data?,
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

    func update(uuid: UUID) -> DataResource {
        return DataResource(
            url: url,
            method: method,
            body: body,
            uuid: uuid,
            authorizationNeeded: authorizationNeeded,
            parseData: parseData)
    }

    static func randomBoundary() -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return "XXX\(String(alphabet.shuffled()).dropFirst(alphabet.count - 10))XXX"
    }

    static func multipartFormData(with data: Data, boundary: Boundary, mimeType: String) -> Data {
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

final class DownloadResource: Resource {
    let url: String
    let method: HTTPMethod
    let body: Data?
    let fileName: String
    var authorizationNeeded = true
    var headers = Headers()
    let uuid: UUID

    init(
        url: String,
        method: HTTPMethod,
        body: Data?,
        fileName: String,
        uuid: UUID = UUID(),
        authorizationNeeded: Bool = true) {
        self.url = url
        self.method = method
        self.body = body
        self.fileName = fileName
        self.uuid = uuid
        self.authorizationNeeded = authorizationNeeded
    }

    func update(uuid: UUID) -> DownloadResource {
        return DownloadResource(
            url: url,
            method: method,
            body: body,
            fileName: fileName,
            uuid: uuid,
            authorizationNeeded: authorizationNeeded)
    }
}
