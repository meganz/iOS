import MEGADomain
import MEGASwiftUI
import SwiftUI

struct VideoCellPreviewEntity: Equatable {
    let isFavorite: Bool
    let imageContainer: any ImageContaining
    let duration: String
    let title: String
    let size: String
    let isPublicLink: Bool
    let label: NodeLabelTypeEntity?
    
    var shouldShowCircleImage: Bool {
        return !title.isEmpty && !size.isEmpty
    }
    
    static func == (lhs: VideoCellPreviewEntity, rhs: VideoCellPreviewEntity) -> Bool {
        let isImageContainerEqual = lhs.imageContainer.image == rhs.imageContainer.image
        && lhs.imageContainer.type == rhs.imageContainer.type
        
        return lhs.isFavorite == rhs.isFavorite
        && isImageContainerEqual
        && lhs.duration == rhs.duration
        && lhs.title == rhs.title
        && lhs.size == rhs.size
        && lhs.isPublicLink == rhs.isPublicLink
        && lhs.label == rhs.label
    }
}

extension VideoCellPreviewEntity {
    
    static let placeholder = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "",
        title: "",
        size: "",
        isPublicLink: false,
        label: nil
    )
}
