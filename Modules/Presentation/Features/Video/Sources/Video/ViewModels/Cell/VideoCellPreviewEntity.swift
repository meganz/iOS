import MEGADomain
import MEGAPresentation
import MEGASwiftUI
import MEGAUIKit
import SwiftUI

struct VideoCellPreviewEntity: Equatable {
    let isFavorite: Bool
    let imageContainer: any ImageContaining
    let duration: String
    let title: String
    let description: String?
    let tags: [String]
    let searchText: String?
    let size: String
    let isExported: Bool
    let label: NodeLabelTypeEntity?
    let hasThumbnail: Bool
    let isDownloaded: Bool

    var shouldShowCircleImage: Bool {
        isExported
    }

    func makeDescriptionAttributedString(
        withPrimaryTextColor primaryTextColor: Color,
        highlightedTextColor: Color
    ) -> AttributedString? {
        guard let description else { return nil }
        return AttributedString(
            description.highlightedStringWithKeyword(
                searchText,
                primaryTextColor: UIColor(primaryTextColor),
                highlightedTextColor: UIColor(highlightedTextColor),
                normalFont: .preferredFont(forTextStyle: .caption1),
                highlightedFont: .preferredFont(style: .caption1, weight: .bold)
            )
        )
    }

    func makeAttributedStringsForTags(
        withPrimaryTextColor primaryTextColor: Color,
        highlightedTextColor: Color
    ) -> [AttributedString]? {
        guard let searchText, tags.isNotEmpty else { return nil }

        return tags.map {
            var attributedString = AttributedString(
                ("#" + $0)
                    .forceLeftToRight()
                    .highlightedStringWithKeyword(
                        searchText.removingFirstLeadingHash(),
                        primaryTextColor: UIColor(primaryTextColor),
                        highlightedTextColor: UIColor(highlightedTextColor)
                    )
            )

            attributedString.font = .subheadline.weight(.medium)
            return attributedString
        }
    }

    static func == (lhs: VideoCellPreviewEntity, rhs: VideoCellPreviewEntity) -> Bool {
        let isImageContainerEqual = lhs.imageContainer.image == rhs.imageContainer.image
        && lhs.imageContainer.type == rhs.imageContainer.type
        
        return lhs.isFavorite == rhs.isFavorite
        && isImageContainerEqual
        && lhs.duration == rhs.duration
        && lhs.title == rhs.title
        && lhs.description == lhs.description
        && lhs.tags == rhs.tags
        && lhs.searchText == rhs.searchText
        && lhs.size == rhs.size
        && lhs.isExported == rhs.isExported
        && lhs.label == rhs.label
        && lhs.isDownloaded == rhs.isDownloaded
    }
}

extension VideoCellPreviewEntity {
    
    static let placeholder = VideoCellPreviewEntity(
        isFavorite: false,
        imageContainer: PreviewImageContainerFactory.withColor(.black, size: CGSize(width: 1000, height: 1000)),
        duration: "",
        title: "",
        description: nil,
        tags: [],
        searchText: nil,
        size: "",
        isExported: false,
        label: nil,
        hasThumbnail: true,
        isDownloaded: true
    )
}

extension VideoCellPreviewEntity {
    
    func labelImage(source labelAssets: VideoConfig.RowAssets.LabelAssets) -> UIImage? {
        switch label {
        case .unknown, .none: nil
        case .red: labelAssets.redImage
        case .orange: labelAssets.orangeImage
        case .yellow: labelAssets.yellowImage
        case .green: labelAssets.greenImage
        case .blue: labelAssets.blueImage
        case .purple: labelAssets.purpleImage
        case .grey: labelAssets.greyImage
        }
    }
    
    func downloadedImage(source rowAssets: VideoConfig.RowAssets) -> UIImage? {
        isDownloaded ? rowAssets.downloadedImage : nil
    }
}
