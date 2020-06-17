//
//  Resource.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//
import Foundation

public protocol Resource {
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
