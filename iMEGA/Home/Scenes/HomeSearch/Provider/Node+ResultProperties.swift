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

    private enum Constants {
        static let propertyIconSize = 12.0
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

    private static func imageContent(image: UIImage, size: CGFloat) -> Content {
        .icon(image: image, layoutConfig: .init(scalable: true, size: size))
    }

    static let downloaded: Self = .init(
        id: NodePropertyId.downloaded.rawValue,
        content: imageContent(image: MEGAAssets.UIImage.arrowDownCircle, size: 14),
        vibrancyEnabled: false,
        placement: { mode in
            switch mode {
            case .list: .secondary(.trailing)
            case .thumbnail: .none
            }
        }
    )

    static let versioned: Self = .init(
        id: NodePropertyId.versioned.rawValue,
        content: imageContent(image: MEGAAssets.UIImage.clockRotate, size: 13),
        vibrancyEnabled: false,
        placement: { mode in
            switch mode {
            case .list: .secondary(.leading)
            case .thumbnail: .none
            }
        }
    )

    static let favorite: Self = .init(
        id: NodePropertyId.favorite.rawValue,
        content: imageContent(image: MEGAAssets.UIImage.heart, size: 12),
        vibrancyEnabled: false,
        accessibilityLabel: Strings.Localizable.favourite,
        placement: { mode in
            switch mode {
            case .list: .prominent(.trailing)
            case .thumbnail: .secondary(.trailingEdge)
            }
        }
    )

    static var linked: ResultProperty {
        .init(
            id: NodePropertyId.linked.rawValue,
            content: imageContent(image: MEGAAssets.UIImage.link01, size: 16),
            vibrancyEnabled: false,
            accessibilityLabel: Strings.Localizable.shared,
            placement: { mode in
                switch mode {
                case .list: .prominent(.trailing)
                case .thumbnail: .secondary(.trailingEdge)
                }
            }
        )
    }

    static func label(path: String, accessibilityLabel: String) -> ResultProperty {
        let overriddenPath = "\(path)Small"
        let image = MEGAAssets.UIImage.image(named: overriddenPath) ?? {
            assertionFailure("Label image named \(overriddenPath) not found")
            return MEGAAssets.UIImage.red
        }()

        return .init(
            id: NodePropertyId.label.rawValue,
            content: .icon(image: image, layoutConfig: .init(scalable: true, size: 9, renderingMode: .original)),
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
            content: .icon(image: icon, layoutConfig: .init(scalable: true, size: Constants.propertyIconSize)),
            vibrancyEnabled: vibrancyEnabled,
            accessibilityLabel: accessibilityLabel,
            placement: placement
        )
    }
}
