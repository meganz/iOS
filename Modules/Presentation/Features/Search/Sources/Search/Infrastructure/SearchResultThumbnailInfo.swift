import SwiftUI

public struct SearchResultThumbnailInfo: Identifiable, Sendable {
    public enum DisplayMode: Sendable {
        case file
        case folder
    }

    public let id: String

    let displayMode: DisplayMode
    let title: String
    let subtitle: String
    let iconIndicatorPath: String?
    let duration: String?
    let isVideoIconHidden: Bool
    let takedownImage: UIImage?
    let hasThumbnail: Bool

    let thumbnailImageData: @Sendable () async -> Data
    let propertiesData: @Sendable () async -> [UIImage]
    let downloadVisibilityData: @Sendable () async -> Bool

    public init(
        id: String,
        displayMode: DisplayMode,
        title: String,
        subtitle: String,
        iconIndicatorPath: String?,
        duration: String?,
        isVideoIconHidden: Bool,
        takedownImage: UIImage? = nil,
        hasThumbnail: Bool,
        thumbnailImageData: @Sendable @escaping () async -> Data,
        propertiesData: @Sendable @escaping () async -> [UIImage],
        downloadVisibilityData: @Sendable @escaping () async -> Bool
    ) {
        self.id = id
        self.displayMode = displayMode
        self.title = title
        self.subtitle = subtitle
        self.iconIndicatorPath = iconIndicatorPath
        self.duration = duration
        self.isVideoIconHidden = isVideoIconHidden
        self.takedownImage = takedownImage
        self.hasThumbnail = hasThumbnail

        self.thumbnailImageData = thumbnailImageData
        self.propertiesData = propertiesData
        self.downloadVisibilityData = downloadVisibilityData
    }
}
