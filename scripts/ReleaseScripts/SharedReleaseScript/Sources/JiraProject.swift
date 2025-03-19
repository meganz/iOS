import Foundation

public struct JiraProject: Decodable, Sendable {
    public let name: String
    public let id: Int64
}
