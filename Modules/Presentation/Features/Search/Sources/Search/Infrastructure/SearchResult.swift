import Foundation
import UIKit

public struct SearchResult: Identifiable, Sendable {
    public let id: ResultId
    /// this is needed to know in the thumbnail grid mode if given result should
    /// be rendered as horizontal (folder) or vertical (file) layout
    public let thumbnailDisplayMode: ResultCellLayout.ThumbnailMode
    public let backgroundDisplayMode: VerticalBackgroundViewMode
    public let title: String
    public let note: String?
    public let tags: [String]
    public let isSensitive: Bool
    public let hasThumbnail: Bool
    public let description: @Sendable (ResultCellLayout) -> String
    public let type: ResultType
    public let properties: [ResultProperty]
    public let thumbnailImageData: @Sendable () async -> Data
    public let swipeActions: @Sendable (ViewDisplayMode) -> [SearchResultSwipeAction]

    public init(
        id: ResultId,
        /// result need to specify what mode it needs to be presented in
        /// in thumbnail layout, for list layout all nodes are presented the same way
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode,
        /// encodes if background of the vertical cell should present
        /// a preview or a solid background with an icon
        backgroundDisplayMode: VerticalBackgroundViewMode,
        title: String,
        note: String?,
        tags: [String],
        isSensitive: Bool,
        hasThumbnail: Bool,
        description: @escaping @Sendable (ResultCellLayout) -> String,
        type: ResultType,
        /// represents various properties such as label color, offline status, versioning etc;
        /// elements in the array define how they should be rendered (icon, text ..) and where
        /// they should be placed. Placement is encoded in a semantic way
        properties: [ResultProperty],
        thumbnailImageData: @escaping @Sendable () async -> Data,
        swipeActions: @escaping @Sendable (ViewDisplayMode) -> [SearchResultSwipeAction]
    ) {
        self.id = id
        self.thumbnailDisplayMode = thumbnailDisplayMode
        self.backgroundDisplayMode = backgroundDisplayMode
        self.title = title
        self.note = note
        self.tags = tags
        self.isSensitive = isSensitive
        self.hasThumbnail = hasThumbnail
        self.description = description
        self.type = type
        self.properties = properties
        self.thumbnailImageData = thumbnailImageData
        self.swipeActions = swipeActions
    }
}

public typealias ResultId = UInt64

extension SearchResult: Equatable {
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.note == rhs.note &&
        lhs.tags == rhs.tags &&
        lhs.isSensitive == rhs.isSensitive &&
        lhs.hasThumbnail == rhs.hasThumbnail &&
        lhs.description(.list) == rhs.description(.list) &&
        lhs.description(.thumbnail(.horizontal)) == rhs.description(.thumbnail(.horizontal)) &&
        lhs.description(.thumbnail(.vertical)) == rhs.description(.thumbnail(.vertical)) &&
        lhs.properties == rhs.properties &&
        lhs.type == rhs.type
    }
}
