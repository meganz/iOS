import MEGADomain
import UIKit

extension VideoCellPreviewEntity {
    
    static let standard = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "The Office Season 8 Episode 23 | Turf War",
        size: "2.00 GB",
        isExported: false,
        label: nil
    )
    
    static let favorite = VideoCellPreviewEntity(
        isFavorite: true,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "Item that has favorite",
        size: "2.00 GB",
        isExported: false,
        label: nil
    )
    
    static let hasPublicLink = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "Item that has public link",
        size: "2.00 GB",
        isExported: true,
        label: nil
    )
    
    static let hasLabel = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: "Item that has label",
        size: "2.00 GB",
        isExported: false,
        label: .purple
    )
    
    static func all(title: TitleType) -> VideoCellPreviewEntity { VideoCellPreviewEntity(
        isFavorite: true,
        imageContainer: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1000, height: 1000)),
        duration: "00:36:00",
        title: title.rawValue,
        size: "2.00 GB",
        isExported: true,
        label: .blue
    ) }
    
    enum TitleType: String {
        case short = "A title"
        case medium = "A Medium Title 8 Episode 23 | Turf War"
        case long = "A long title - The Office Season 8 Episode 23 | Turf War | all complete | long title long title long title long title long title long title long title long title"
    }
}
