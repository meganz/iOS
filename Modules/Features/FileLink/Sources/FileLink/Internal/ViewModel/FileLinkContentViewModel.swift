import Combine
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI

@MainActor
package final class FileLinkContentViewModel: ObservableObject {
    /// What the preview area shows.
    package enum Preview: Equatable {
        /// A loaded image, filling the preview area. `videoDuration` is set for videos only and
        /// carries the play button and the duration stamp with it.
        case media(image: Image, videoDuration: String?)
        /// The file type icon. Every non-media file shows this, and so does media whose image could
        /// not be loaded.
        case fileTypeIcon(Image)
    }

    package let name: String
    /// The size on its own, or the duration and the size for media that carries one.
    package let details: String

    @Published package private(set) var preview: Preview

    private let node: NodeEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let fileNodeOpener: any FileLinkNodeOpenerProtocol
    /// Not published: nothing on screen changes while a file is being opened, this only keeps a second
    /// ask from getting through. See `openFile()`.
    private var isOpeningFile = false

    package init(
        node: NodeEntity,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        fileNodeOpener: some FileLinkNodeOpenerProtocol
    ) {
        self.node = node
        self.thumbnailLoader = thumbnailLoader
        self.fileNodeOpener = fileNodeOpener
        name = node.name
        details = Self.details(for: node)
        preview = .fileTypeIcon(MEGAAssets.Image.image(forFileName: node.name))
    }

    /// Loads the image behind the preview area, leaving the file type icon in place when there is
    /// none to load.
    ///
    /// Only images and videos ask for one. A PDF carries a preview of its first page, but the design
    /// asks for the file type icon there, so the file type decides this and the attribute only
    /// decides whether the request is worth making.
    package func loadPreview() async {
        guard node.name.fileExtensionGroup.isVisualMedia, node.hasPreview else { return }

        guard let container = try? await thumbnailLoader.loadImage(for: node, type: .preview) else { return }

        preview = .media(image: container.image, videoDuration: Self.videoDuration(for: node))
    }

    package func openFile() async {
        guard !isOpeningFile else { return }
        isOpeningFile = true
        defer { isOpeningFile = false }

        await fileNodeOpener.openNode(handle: node.handle)
    }

    private static func details(for node: NodeEntity) -> String {
        let size = String.memoryStyleString(fromByteCount: Int64(node.size))

        guard node.name.fileExtensionGroup.isMultiMedia, let duration = duration(for: node) else {
            return size
        }
        return "\(duration) • \(size)"
    }

    private static func videoDuration(for node: NodeEntity) -> String? {
        guard node.name.fileExtensionGroup.isVideo else { return nil }
        return duration(for: node)
    }

    private static func duration(for node: NodeEntity) -> String? {
        guard node.duration > 0 else { return nil }

        return Duration.seconds(node.duration).formatted(
            node.duration >= 3600
                ? .time(pattern: .hourMinuteSecond(padHourToLength: 1))
                : .time(pattern: .minuteSecond(padMinuteToLength: 1))
        )
    }
}
