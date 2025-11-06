import UIKit

extension ResultProperty {
    private static let defaultLayoutConfig = Content.LayoutConfiguration(scalable: true, size: 12)
    private static let nonScalableLayoutConfig = Content.LayoutConfiguration(scalable: false, size: 12)
    static var previewSamples: [Self] {
        [
            .init(
                id: "1",
                content: .icon(image: UIImage(systemName: "figure.walk")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: true,
                placement: { _ in .prominent(.trailing) }
            ),
            .init(
                id: "2",
                content: .icon(image: UIImage(systemName: "exclamationmark.triangle")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .secondary(.leading) }
            ),
            .init(
                id: "3",
                content: .icon(image: UIImage(systemName: "cloud")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .secondary(.trailing) }
            ),
            .init(
                id: "4",
                content: .icon(image: UIImage(systemName: "key.horizontal")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .secondary(.trailing) }
            ),
            .init(
                id: "5",
                content: .icon(image: UIImage(systemName: "trash.circle.fill")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .secondary(.trailingEdge) }
            ),
            .init(
                id: "6",
                content: .icon(image: UIImage(systemName: "play.fill")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .previewOverlay }
            ),
            .init(
                id: "7",
                content: .text("Middle line content"),
                vibrancyEnabled: false,
                placement: { _ in .auxLine }
            ),
            .init(
                id: "8",
                content: .icon(image: UIImage(systemName: "hand.point.up.fill")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .prominent(.trailing) }
            ),
            .init(
                id: "9",
                content: .icon(image: UIImage(systemName: "scissors")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .secondary(.leading) }
            ),
            .init(
                id: "10",
                content: .icon(image: UIImage(systemName: "drop.fill")!, layoutConfig: defaultLayoutConfig),
                vibrancyEnabled: false,
                placement: { _ in .secondary(.trailing) }
            )
        ]
    }
}

extension ResultProperty {
    static let play: Self = .init(
        id: "1",
        content: .icon(image: UIImage(systemName: "play.fill")!, layoutConfig: nonScalableLayoutConfig),
        vibrancyEnabled: false,
        placement: { _ in .secondary(.leading) }
    )
    static let duration: Self = .init(
        id: "2",
        content: .text("20:00"),
        vibrancyEnabled: false,
        placement: { _ in .secondary(.leading) }
    )
    static let someProminentIcon: Self = .init(
        id: "3",
        content: .icon(image: UIImage(systemName: "cloud")!, layoutConfig: defaultLayoutConfig),
        vibrancyEnabled: false,
        placement: { _ in .prominent(.trailing) }
    )
    static let someTopIcon: Self = .init(
        id: "4",
        content: .icon(image: UIImage(systemName: "drop")!, layoutConfig: defaultLayoutConfig),
        vibrancyEnabled: false,
        placement: { _ in .secondary(.trailingEdge) }
    )
}
