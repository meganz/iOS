import MEGADomain
import MEGASwift
import SwiftUI

/// A decorator component that decorates ThumbnailLoader instance to have fallback icon when failed to generate image from the loader.
struct ThumbnailLoaderWithFallbackIcon: ThumbnailLoaderProtocol {
    
    private let decoratee: any ThumbnailLoaderProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    
    init(decoratee: some ThumbnailLoaderProtocol, nodeIconUseCase: some NodeIconUsecaseProtocol) {
        self.decoratee = decoratee
        self.nodeIconUseCase = nodeIconUseCase
    }
    
    func initialImage(for node: NodeEntity, type: ThumbnailTypeEntity, placeholder: @Sendable () -> Image) -> any ImageContaining {
        if node.hasThumbnail {
            return decoratee.initialImage(for: node, type: type, placeholder: placeholder)
        } else {
            let image = initialFallbackImage(for: node, placeholder: placeholder)
            return ImageContainer(image: image, type: type.toImageType())
        }
    }
    
    private func initialFallbackImage(for node: NodeEntity, placeholder: @Sendable () -> Image) -> Image {
        let iconData = nodeIconUseCase.iconData(for: node)
        return if let uiImage = UIImage(data: iconData) {
            Image(uiImage: uiImage)
        } else {
            placeholder()
        }
    }
    
    func loadImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> AnyAsyncSequence<any ImageContaining> {
        if node.hasThumbnail {
            try await decoratee.loadImage(for: node, type: type)
        } else {
            SingleItemAsyncSequence(item: ImageContainer(image: loadFallbackImage(for: node), type: type.toImageType()))
                .eraseToAnyAsyncSequence()
        }
    }
    
    private func loadFallbackImage(for node: NodeEntity) -> Image {
        let iconData = nodeIconUseCase.iconData(for: node)
        return image(from: iconData)
    }
    
    private func image(from iconData: Data) -> Image {
        if let uiImage = UIImage(data: iconData) {
            Image(uiImage: uiImage)
        } else {
            Image(uiImage: UIImage.withColor(.clear, size: CGSize(width: 1, height: 1)))
        }
    }
}

private extension UIImage {
    
    static func withColor(_ color: UIColor, size: CGSize) -> UIImage {
        guard size.width > 0 && size.height > 0 else {
            return UIImage()
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
