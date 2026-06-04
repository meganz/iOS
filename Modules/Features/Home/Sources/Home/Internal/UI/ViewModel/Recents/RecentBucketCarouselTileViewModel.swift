import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI
import UIKit

@MainActor
final class RecentBucketCarouselTileViewModel: ObservableObject {
    @Published private(set) var image: Image
    @Published private(set) var hasThumbnail: Bool

    private let node: NodeEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol

    init(
        node: NodeEntity,
        thumbnailUseCase: any ThumbnailUseCaseProtocol = ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
    ) {
        self.node = node
        self.thumbnailUseCase = thumbnailUseCase
        self.image = MEGAAssets.Image.image(forFileExtension: node.name.pathExtension)
        self.hasThumbnail = false
    }

    func loadThumbnail() async {
        guard node.hasThumbnail,
              let thumbnail = try? await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail),
              let uiImage = UIImage(contentsOfFile: thumbnail.url.path) else {
            return
        }
        apply(thumbnail: uiImage)
    }

    private func apply(thumbnail: UIImage) {
        image = Image(uiImage: thumbnail)
        hasThumbnail = true
    }
}
