import MEGADomain
import UIKit

extension VideoCellPreviewEntity {
    
    static let standard = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "The Office Season 8 Episode 23 | Turf War",
        size: "2.00 GB",
        isPublicLink: false,
        label: nil
    )
    
    static let favorite = VideoCellPreviewEntity(
        isFavorite: true,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "Item that has favorite",
        size: "2.00 GB",
        isPublicLink: false,
        label: nil
    )
    
    static let hasPublicLink = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "Item that has public link",
        size: "2.00 GB",
        isPublicLink: true,
        label: nil
    )
    
    static let hasLabel = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "Item that has label",
        size: "2.00 GB",
        isPublicLink: false,
        label: .purple
    )
    
    static let all = VideoCellPreviewEntity(
        isFavorite: true,
        imageContainer: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "The Office Season 8 Episode 23 | Turf War | all complete | long title long title long title long title long title long title long title long title",
        size: "2.00 GB",
        isPublicLink: true,
        label: .blue
    )
}
