import Foundation

/// Represents a single results of search action
/// still deciding which one to use
/// protocol or struct
public protocol SearchResultProtocol: Identifiable {
    var id: ResultId { get }
    var title: String { get }
    var description: String { get }
    var properties: [Property] { get }
    func loadThumbnailImageData() async throws -> Data
    var type: ResultType { get }
}

public struct SearchResult: Identifiable {
    public let id: ResultId
    public let title: String
    public let description: String
    public let properties: [Property]
    public let thumbnailImageData: () async -> Data
    public let type: ResultType
    
    public init(
        id: ResultId,
        title: String,
        description: String,
        properties: [Property],
        thumbnailImageData: @escaping () async -> Data,
        type: ResultType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.properties = properties
        self.thumbnailImageData = thumbnailImageData
        self.type = type
    }
}

public struct ResultId: Hashable {
    let id: String
}

extension ResultId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        id = value
    }
}

extension ResultId: CustomStringConvertible {
    public var description: String {
        id
    }
}

extension SearchResult: Equatable {
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.properties == rhs.properties &&
        lhs.type == rhs.type
    }
}

extension Property: Equatable {
    public static func == (lhs: Property, rhs: Property) -> Bool {
        lhs.icon == rhs.icon
    }
}

