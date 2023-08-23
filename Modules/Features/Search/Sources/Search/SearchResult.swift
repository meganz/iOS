import Foundation
import MEGADomain

/// Represents a single results of search action
/// still deciding which one to use
/// protocol or struct
public protocol SearchResultProtocol: Identifiable {
    var id: ResultId { get }
    var title: String { get }
    var description: String { get }
    var properties: [Property] { get }
    func loadThumbnailImageData() async throws -> Data
    func buildMenu() async -> ContextMenuBuilder
    var type: ResultType { get }
}

public struct SearchResult: Identifiable {
    public let id: ResultId
    public let title: String
    public let description: String
    public let properties: [Property]
    public let thumbnailImageData: () async -> Data
    public let menuBuilder: () async -> ContextMenuBuilder
    public let type: ResultType
    
    public init(
        id: ResultId,
        title: String,
        description: String,
        properties: [Property],
        thumbnailImageData: @escaping () async -> Data,
        menuBuilder: @escaping () async -> ContextMenuBuilder,
        type: ResultType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.properties = properties
        self.thumbnailImageData = thumbnailImageData
        self.menuBuilder = menuBuilder
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
