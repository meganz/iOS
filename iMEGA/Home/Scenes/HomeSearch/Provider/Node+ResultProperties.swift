import MEGAL10n
import Search

enum NodePropertyId: String {
    case favorite
    case versioned
    case linked
    case label
    case takenDown
    case downloaded
    case videoDuration
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
    
    static func duration(string: String) -> Self {
        .init(
            id: NodePropertyId.videoDuration.rawValue,
            content: .text(string),
            vibrancyEnabled: false,
            placement: { mode in
                if mode == .thumbnail(.vertical) {
                    return .secondary(.leading)
                } else {
                    return .none
                }
            }
        )
    }
    
    static var playIcon: Self {
        .init(
            id: NodePropertyId.playIcon.rawValue,
            content: .icon(image: UIImage.videoList, scalable: false),
            vibrancyEnabled: false,
            placement: { mode in 
                if mode == .thumbnail(.vertical) {
                    return .secondary(.leading)
                } else {
                    return .previewOverlay
                }
            }
        )
    }
    
    static var downloaded: Self {
        .init(
            propertyId: .downloaded,
            icon: UIImage.downloaded,
            vibrancyEnabled: false,
            placement: { mode in
                switch mode {
                case .list:
                    return .secondary(.trailing)
                case .thumbnail(.vertical):
                    return .secondary(.trailing)
                case .thumbnail(.horizontal):
                    return .secondary(.trailing)
                }
            }
        )
    }
    
    static var versioned: Self = .init(
        propertyId: .versioned,
        icon: UIImage.versionedThumbnail,
        vibrancyEnabled: false,
        placement: { mode in
            switch mode {
            case .list:
                return .secondary(.leading)
            case .thumbnail(.vertical):
                return .secondary(.trailingEdge)
            case .thumbnail(.horizontal):
                return .secondary(.leading)
            }
        }
    )
    
    static var favorite: Self = .init(
        propertyId: .favorite,
        icon: UIImage.favouriteThumbnail,
        vibrancyEnabled: false,
        accessibilityLabel: Strings.Localizable.favourite,
        placement: { mode in
            switch mode {
            case .list:
                return .prominent
            case .thumbnail(.vertical):
                return .secondary(.trailingEdge)
            case .thumbnail(.horizontal):
                return .secondary(.leading)
            }
        }
    )
    
    static var linked: ResultProperty {
        .init(
            propertyId: .linked,
            icon: UIImage.linkedThumbnail,
            vibrancyEnabled: false,
            accessibilityLabel: Strings.Localizable.shared,
            placement: { mode in
                switch mode {
                case .list:
                    return .prominent
                case .thumbnail(.vertical):
                    return .secondary(.trailingEdge)
                case .thumbnail(.horizontal):
                    return .secondary(.trailing)
                }
            }
        )
    }
    
    static func label(path: String, accessibilityLabel: String) -> ResultProperty {
        .init(
            id: NodePropertyId.label.rawValue,
            content: .icon(image: UIImage(named: path)!, scalable: false),
            vibrancyEnabled: false,
            accessibilityLabel: accessibilityLabel,
            placement: { _ in
                    .prominent
            }
        )
    }
    
    static let takenDown: Self = .init(
        propertyId: .takenDown,
        icon: UIImage.isTakedown,
        vibrancyEnabled: true, // this will make title of result stand out
        placement: { _ in
                .prominent
        }
    )
    
    init(
        propertyId: NodePropertyId,
        image: UIImage,
        vibrancyEnabled: Bool,
        accessibilityLabel: String = "",
        placement: @Sendable @escaping (Search.ResultCellLayout) -> PropertyPlacement
    ) {
        self.init(
            id: propertyId.rawValue,
            content: .icon(image: image, scalable: true),
            vibrancyEnabled: vibrancyEnabled,
            accessibilityLabel: accessibilityLabel,
            placement: placement
        )
    }
    
    init(
        propertyId: NodePropertyId,
        icon: UIImage,
        vibrancyEnabled: Bool,
        accessibilityLabel: String = "",
        placement: @Sendable @escaping (Search.ResultCellLayout) -> PropertyPlacement
    ) {
        self.init(
            id: propertyId.rawValue,
            content: .icon(image: icon, scalable: true),
            vibrancyEnabled: vibrancyEnabled,
            accessibilityLabel: accessibilityLabel,
            placement: placement
        )
    }
}
