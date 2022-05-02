//
//  File.swift
//  
//
//  Created by Christian Braun on 02.05.22.
//

import Foundation

public struct TaskIdentifier: Equatable {
    public enum TaskType: String {
        case data, download, upload
    }
    static let seperator = "###Santa-Seperator###"

    public let type: TaskType
    public let uuid: UUID
    public let additional: String?

    public var stringValue: String {
        [type.rawValue, uuid.uuidString, additional]
            .compactMap { $0 }
            .joined(separator: Self.seperator)
    }

    init(taskType: TaskType, uuid: UUID, additional: String?) {
        self.uuid = uuid
        self.additional = additional
        self.type = taskType
    }

    init?(taskDescription: String?) {
        guard let taskDescription = taskDescription else {
            return nil
        }
        let components = taskDescription.components(separatedBy: Self.seperator)
        guard components.count >= 2,
              let type = TaskType(rawValue: components[0]),
              let uuid = UUID(uuidString: components[1]) else {
            return nil
        }
        self.type = type
        self.uuid = uuid
        self.additional = components.count == 3 ? components.last : nil
    }
}
