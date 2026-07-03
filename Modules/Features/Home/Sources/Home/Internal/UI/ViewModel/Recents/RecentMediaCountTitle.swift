import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

/// Builds the count title for a media Recents bucket, distinguishing images from videos.
/// - Images only: "X images"
/// - Videos only: "X videos"
/// - Mixed: "X images and X videos"
enum RecentMediaCountTitleBuilder {
    static func make(for nodes: [NodeEntity]) -> String {
        make(
            imageCount: nodes.filter(\.fileExtensionGroup.isImage).count,
            videoCount: nodes.filter(\.fileExtensionGroup.isVideo).count
        )
    }

    static func make(imageCount: Int, videoCount: Int) -> String {
        switch (imageCount, videoCount) {
        case (_, 0):
            Strings.Localizable.Recents.Section.Thumbnail.Count.image(imageCount)
        case (0, _):
            Strings.Localizable.Recents.Section.Thumbnail.Count.video(videoCount)
        default:
            Strings.Localizable.Recents.Section.Thumbnail.Count.ImageAndVideo.image(imageCount)
                + " " + Strings.Localizable.Recents.Section.Thumbnail.Count.ImageAndVideo.video(videoCount)
        }
    }
}
