import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwift
import SwiftUI

@MainActor
final class RecentBucketCarouselSheetViewModel: ObservableObject {
    private static let extendedTileCount = 12
    private static let compactTileCount = 6

    enum Action {
        case openNode(handle: HandleEntity, siblings: [HandleEntity])
        case showInLocation(HandleEntity)
        case seeAll
    }

    struct Header: Equatable {
        let icon: Image
        let title: String
        let subtitle: String
    }

    let header: Header
    let showsShowInLocation: Bool
    let displayedNodes: [NodeEntity]

    private let bucket: RecentActionBucketEntity
    private let actionHandler: @MainActor (Action) -> Void

    init(
        bucket: RecentActionBucketEntity,
        actionHandler: @escaping @MainActor (Action) -> Void
    ) {
        self.bucket = bucket
        self.actionHandler = actionHandler
        self.displayedNodes = Array(bucket.nodes.prefix(Self.maxTilesShown(for: bucket)))
        self.showsShowInLocation = bucket.parent != nil
        self.header = Self.makeHeader(for: bucket)
    }

    private static func maxTilesShown(for bucket: RecentActionBucketEntity) -> Int {
        bucket.nodes.count > extendedTileCount ? extendedTileCount : compactTileCount
    }

    func onTileTap(handle: HandleEntity) {
        actionHandler(.openNode(handle: handle, siblings: bucket.nodes.map(\.handle)))
    }

    func onShowInLocationTap() {
        guard let parentHandle = bucket.parent?.handle else { return }
        actionHandler(.showInLocation(parentHandle))
    }

    func onSeeAllTap() {
        actionHandler(.seeAll)
    }

    private static func makeHeader(for bucket: RecentActionBucketEntity) -> Header {
        Header(
            icon: headerIcon(for: bucket.type),
            title: bucket.parent?.name ?? "",
            subtitle: headerSubtitle(for: bucket.type)
        )
    }

    private static func headerIcon(for type: RecentActionBucketType) -> Image {
        switch type {
        case .singleFile(let node), .singleMedia(let node):
            MEGAAssets.Image.image(forFileExtension: node.name.pathExtension)
        case .multipleMedia:
            MEGAAssets.Image.filetypeImagesStack
        case .mixedFiles:
            MEGAAssets.Image.filetypeGenericStack
        }
    }

    private static func headerSubtitle(for type: RecentActionBucketType) -> String {
        switch type {
        case .singleFile, .singleMedia:
            return ""
        case let .multipleMedia(nodes):
            return Strings.Localizable.Recents.Section.Thumbnail.Count.image(nodes.count)
        case let .mixedFiles(nodes):
            return Strings.Localizable.General.Format.Count.file(nodes.count)
        }
    }
}
