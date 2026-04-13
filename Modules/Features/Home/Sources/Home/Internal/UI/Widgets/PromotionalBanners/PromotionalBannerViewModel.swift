import MEGASwiftUI
import SwiftUI

@MainActor
final class PromotionalBannerViewModel: ObservableObject, Identifiable {
    let input: PromotionBannerInput

    @Published private(set) var backgroundImage: Image?
    @Published private(set) var bannerImage: Image?

    private let imageLoader: any ImageLoadingProtocol

    init(
        input: PromotionBannerInput,
        imageLoader: some ImageLoadingProtocol = ImageLoader()
    ) {
        self.input = input
        self.imageLoader = imageLoader
    }

    func loadImages() async {
        guard backgroundImage == nil || bannerImage == nil else { return }

        async let backgroundUIImage = imageLoader.loadImage(from: input.backgroundURL)
        async let bannerUIImage = imageLoader.loadImage(from: input.imageURL)

        let (bgImage, bnrImage) = await (backgroundUIImage, bannerUIImage)
        guard !Task.isCancelled else { return }

        if let bgImage {
            backgroundImage = Image(uiImage: bgImage)
        }
        if let bnrImage {
            bannerImage = Image(uiImage: bnrImage)
        }
    }
}
