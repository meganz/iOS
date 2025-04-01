import MEGAAppPresentation
import SwiftUI

enum PreviewImageContainerFactory {
    public static func withColor(_ color: UIColor, size: CGSize) -> any ImageContaining {
        let image = Image(uiImage: .withColor(color, size: size))
        let container = ImageContainer(image: image, type: .original)
        return container
    }
}
