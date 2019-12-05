//
//  Attachment.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import Foundation

struct Attachment: Codable, Equatable {
    enum DownloadStatus {
        case notDownloaded
        case downloading
        case downloaded
    }

    let id: Int64
    let name: String
    let links: Links

    var fileNameForSaving: String {
        return "\(id)_\(name)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case links = "_links"
    }
}

extension Attachment {
    func downloadStatus(_ webservice: Webservice) -> DownloadStatus {
        guard let dataLink = links.data,
            let dataUrl = URL(string: dataLink)  else {
                preconditionFailure("Data url must be set for attachment")
        }

        if webservice.isTaskActive(for: dataUrl) {
            return .downloading
        } else if DownloadedFilesManager.exists(self) {
            return .downloaded
        } else {
            return .notDownloaded
        }
    }
}
