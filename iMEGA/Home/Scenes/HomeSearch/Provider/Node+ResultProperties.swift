import MEGAAppPresentation
import MEGAAssets
import MEGAL10n
import Search

enum NodePropertyId: String {
    case favorite
    case versioned
    case linked
    case label
    case takenDown
    case downloaded
    case duration
    case playIcon
}

// extension below provides a simple interface to create and configure
// node properties used in the node collection screens
// each item has a unique id, can provide an image, text or a SwiftUI Spacer() content,
// can force a title of node to render in vibrant color, as well as
// decide in which of the possible semantic positions, at each display mode, it will be placed
// please inspect VerticalThumbnailView.swift, HorizontalThumbnailView.swift and
// SearchResultRowView.swift for exact meaning and positioning
extension ResultProperty {
    private typealias LayoutConfiguration = ResultProperty.Content.LayoutConfiguration
    private typealias Content = ResultProperty.Content
    private static var isCloudDriveRevampEnabled: Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCloudDriveRevamp)
    }

    private enum Constants {
        static let legacyPropertySize = 12.0
        // This is the padding value needed to correct the position the legacy label icon in revamped UI structure
        static let legacyLabelHorizontalPadding: CGFloat = -3
    }

    static func duration(string: String) -> Self {
        .init(
            id: NodePropertyId.duration.rawValue,
            content: .text(string),
            vibrancyEnabled: false,
            placement: { mode in
                switch mode {
                case .thumbnail: .secondary(.leading)
                case .list: .none
                }
            }
        )
    }

    private static func imageContent(
        legacyImage: UIImage,
        revampedImage: UIImage,
        legacyScalable: Bool,
        revampedScalable: Bool,
        revampedSize: CGFloat
    ) -> Content {
        .icon(
            image: isCloudDriveRevampEnabled ? revampedImage : legacyImage,
            layoutConfig: .init(
                scalable: isCloudDriveRevampEnabled ? revampedScalable : legacyScalable,
                size: isCloudDriveRevampEnabled ? revampedSize : Constants.legacyPropertySize
            )
        )
    }

    static let downloaded: Self = {
        let content = imageContent(
            legacyImage: MEGAAssets.UIImage.downloaded,
            revampedImage: MEGAAssets.UIImage.arrowDownCircle,
            legacyScalable: true,
            revampedScalable: true,
            revampedSize: 14
        )

        return .init(
            id: NodePropertyId.downloaded.rawValue,
            content: content,
            vibrancyEnabled: false,
            placement: { mode in
                switch mode {
                case .list: .secondary(.trailing)
                case .thumbnail: isCloudDriveRevampEnabled ? .none : .secondary(.trailing)
                }
            }
        )
    }()

    static let versioned: Self = {
        let content = imageContent(
            legacyImage: MEGAAssets.UIImage.versionedThumbnail,
            revampedImage: MEGAAssets.UIImage.clockRotate,
            legacyScalable: true,
            revampedScalable: true,
            revampedSize: 13
        )
        return .init(
            id: NodePropertyId.versioned.rawValue,
            content: content,
            vibrancyEnabled: false,
            placement: { mode in
                switch mode {
                case .list: .secondary(.leading)
                case .thumbnail: isCloudDriveRevampEnabled ? .none : .secondary(.trailingEdge)
                }
            }
        )
    }()

    static let favorite: Self = {
        let content = imageContent(
            legacyImage: MEGAAssets.UIImage.favouriteThumbnail,
            revampedImage: MEGAAssets.UIImage.heart,
            legacyScalable: true,
            revampedScalable: true,
            revampedSize: 12
        )
        return .init(
            id: NodePropertyId.favorite.rawValue,
            content: content,
            vibrancyEnabled: false,
            accessibilityLabel: Strings.Localizable.favourite,
            placement: { mode in
                switch mode {
                case .list: .prominent(.trailing)
                case .thumbnail: .secondary(.trailingEdge)
                }
            }
        )
    }()

    static var linked: ResultProperty {
        let content = imageContent(
            legacyImage: MEGAAssets.UIImage.linkedThumbnail,
            revampedImage: MEGAAssets.UIImage.link01,
            legacyScalable: true,
            revampedScalable: true,
            revampedSize: 16
        )
        return .init(
            id: NodePropertyId.linked.rawValue,
            content: content,
            vibrancyEnabled: false,
            accessibilityLabel: Strings.Localizable.shared,
            placement: { mode in
                switch mode {
                case .list:
                        .prominent(.trailing)
                case .thumbnail:
                        .secondary(.trailingEdge)
                }
            }
        )
    }

    static func label(path: String, accessibilityLabel: String) -> ResultProperty {
        let overriddenPath = isCloudDriveRevampEnabled ? "\(path)Small" : path

        let image = {
            guard let image = MEGAAssets.UIImage.image(named: overriddenPath) else {
                assertionFailure("Label image named \(overriddenPath) not found")
                return MEGAAssets.UIImage.red
            }
            return image
        }()

        let layoutConfig: LayoutConfiguration = isCloudDriveRevampEnabled
        ? .init(scalable: true, size: 9, renderingMode: .original)
        : .init(scalable: false, size: 16, horizontalPadding: Constants.legacyLabelHorizontalPadding)

        return .init(
            id: NodePropertyId.label.rawValue,
            content: .icon(image: image, layoutConfig: layoutConfig),
            vibrancyEnabled: false,
            accessibilityLabel: accessibilityLabel,
            placement: { _ in .prominent(.leading) }
        )
    }

    static let takenDown: Self = .init(
        propertyId: .takenDown,
        icon: MEGAAssets.UIImage.isTakedown,
        vibrancyEnabled: true, // this will make title of result stand out
        placement: { _ in .prominent(.trailing) }
    )

    init(
        propertyId: NodePropertyId,
        icon: UIImage,
        vibrancyEnabled: Bool,
        accessibilityLabel: String = "",
        placement: @Sendable @escaping (Search.ResultCellLayout) -> PropertyPlacement
    ) {
        self.init(
            id: propertyId.rawValue,
            content: .icon(image: icon, layoutConfig: .init(scalable: true, size: Constants.legacyPropertySize)),
            vibrancyEnabled: vibrancyEnabled,
            accessibilityLabel: accessibilityLabel,
            placement: placement
        )
    }
}
