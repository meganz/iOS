import Foundation
import UIKit

public struct SearchResult: Identifiable, Sendable {
    public let id: ResultId
    public let isFolder: Bool
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
        isFolder: Bool,
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
        self.isFolder = isFolder
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
        lhs.description(.thumbnail) == rhs.description(.thumbnail) &&
        lhs.isFolder == rhs.isFolder &&
        lhs.properties == rhs.properties &&
        lhs.type == rhs.type
    }
}
