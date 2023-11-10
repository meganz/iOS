import Foundation
import UIKit

public struct SearchResult: Identifiable, Sendable {
    public init(
        id: ResultId,
        /// result need to specify what mode it needs to be presented in
        /// in thumbnail layout, for list layout all nodes are presented the same way
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode,
        /// encodes if background of the vertical cell should present
        /// a preview or a solid background with an icon
        backgroundDisplayMode: VerticalBackgroundViewMode,
        title: String,
        description: String,
        type: ResultType,
        /// represents various properties such as labek color, offline status, versioning etc;
        /// elements in the array define how they should be rendered (icon, text ..) and where
        /// they should be placed. Placement is encoded in a semantic way 
        properties: [ResultProperty],
        thumbnailImageData: @escaping @Sendable () async -> Data
    ) {
        self.id = id
        self.thumbnailDisplayMode = thumbnailDisplayMode
        self.backgroundDisplayMode = backgroundDisplayMode
        self.title = title
        self.description = description
        self.type = type
        self.properties = properties
        self.thumbnailImageData = thumbnailImageData
    }
    
    public let id: ResultId
    /// this is needed to know in the thumbnail grid mode if given result should
    /// be rendered as horizontal (folder) or vertical (file) layout
    public let thumbnailDisplayMode: ResultCellLayout.ThumbnailMode
    public let backgroundDisplayMode: VerticalBackgroundViewMode
    public let title: String
    public let description: String
    public let type: ResultType
    public let properties: [ResultProperty]
    public let thumbnailImageData: @Sendable () async -> Data
}

public typealias ResultId = UInt64

extension SearchResult: Equatable {
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.properties == rhs.properties &&
        lhs.type == rhs.type
    }
}
