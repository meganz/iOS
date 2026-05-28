import MEGADesignToken
import SwiftUI
import UIKit

public final class MEGASlider: UISlider {
    @IBInspectable public var thumbRadius: CGFloat = 10
    @IBInspectable public var highlightedThumbRadius: CGFloat = 25
    @IBInspectable public var touchExpansion: CGFloat = 20

    public var minimumTrackColor: UIColor? { didSet { configure() } }
    public var maximumTrackColor: UIColor? { didSet { configure() } }
    public var thumbColor: UIColor? { didSet { configure() } }

    public override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            configure()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        let minColor = minimumTrackColor ?? TokenColors.Components.selectionControl
        let maxColor = maximumTrackColor ?? TokenColors.Background.surface3
        let thColor = thumbColor ?? TokenColors.Components.selectionControl

        setMinimumTrackImage(customMinimumTrackImage(bgColor: minColor), for: .normal)
        maximumTrackTintColor = maxColor

        setThumbImage(thumbImage(bgColor: thColor, radius: thumbRadius), for: .normal)
        setThumbImage(thumbImage(bgColor: thColor, radius: highlightedThumbRadius), for: .highlighted)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            configure()
        }
    }

    /// Custom minimum track image slider background. We need this to render exactly same color as the `thumbImage(UIColor: CGFloat) -> UIImage`.  Setting the color of `minimumTrackTintColor` directly won't render the exactly same color as the `thumbImage(UIColor: CGFloat) -> UIImage`
    /// - Parameter bgColor: Desired tint color replacing the `minimumTrackTintColor`
    /// - Returns: desired color as image type.
    private func customMinimumTrackImage(bgColor: UIColor) -> UIImage {
        let track = UIView()
        track.backgroundColor = bgColor
        track.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

        let renderer = UIGraphicsImageRenderer(bounds: track.bounds)
        return renderer.image { rendererContext in
            track.layer.render(in: rendererContext.cgContext)
        }
    }

    private func thumbImage(bgColor: UIColor, radius: CGFloat) -> UIImage {
        let thumb = UIView()
        thumb.backgroundColor = bgColor

        thumb.frame = CGRect(x: 0, y: radius/2, width: radius, height: radius)
        thumb.layer.cornerRadius = radius/2

        let renderer = UIGraphicsImageRenderer(bounds: thumb.bounds)
        return renderer.image { rendererContext in
            thumb.layer.render(in: rendererContext.cgContext)
        }
    }

    /// Expand the tappable area around the thumb without changing its visual size.
    /// We override hit-testing to detect touches within an inset area around the thumb frame,
    /// making it easier to grab even when the thumb graphic is small.
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let thumbFrame = thumbRect(
            forBounds: bounds,
            trackRect: trackRect(forBounds: bounds),
            value: value
        )
        let hitFrame = thumbFrame.insetBy(dx: -touchExpansion, dy: -touchExpansion)
        if hitFrame.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }
}

public struct MEGASliderView: UIViewRepresentable {
    @Binding public var value: Double
    public let isEnabled: Bool
    public let minimumTrackColor: Color?
    public let maximumTrackColor: Color?
    public let thumbColor: Color?
    public let onEditingChanged: (Bool) -> Void

    public init(
        value: Binding<Double>,
        isEnabled: Bool = true,
        minimumTrackColor: Color? = nil,
        maximumTrackColor: Color? = nil,
        thumbColor: Color? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._value = value
        self.isEnabled = isEnabled
        self.minimumTrackColor = minimumTrackColor
        self.maximumTrackColor = maximumTrackColor
        self.thumbColor = thumbColor
        self.onEditingChanged = onEditingChanged
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public func makeUIView(context: Context) -> MEGASlider {
        let slider = MEGASlider(frame: .zero)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = Float(value)
        slider.isEnabled = isEnabled

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingBegan(_:)),
            for: .touchDown
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingEnded(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        applyColors(to: slider)
        return slider
    }

    public func updateUIView(_ uiView: MEGASlider, context: Context) {
        if !context.coordinator.isEditing, abs(uiView.value - Float(value)) > .ulpOfOne {
            uiView.value = Float(value)
        }
        uiView.isEnabled = isEnabled
        applyColors(to: uiView)
    }

    private func applyColors(to slider: MEGASlider) {
        let newMin = minimumTrackColor.map(UIColor.init)
        if slider.minimumTrackColor != newMin {
            slider.minimumTrackColor = newMin
        }
        let newMax = maximumTrackColor.map(UIColor.init)
        if slider.maximumTrackColor != newMax {
            slider.maximumTrackColor = newMax
        }
        let newThumb = thumbColor.map(UIColor.init)
        if slider.thumbColor != newThumb {
            slider.thumbColor = newThumb
        }
    }

    @MainActor
    public final class Coordinator: NSObject {
        private let parent: MEGASliderView
        fileprivate(set) var isEditing: Bool = false

        init(_ parent: MEGASliderView) { self.parent = parent }

        @objc func valueChanged(_ slider: UISlider) {
            parent.value = Double(slider.value)
        }

        @objc func editingBegan(_ slider: UISlider) {
            isEditing = true
            parent.onEditingChanged(true)
        }

        @objc func editingEnded(_ slider: UISlider) {
            isEditing = false
            parent.onEditingChanged(false)
        }
    }
}

@available(iOS 17.0, *)
#Preview(traits: .fixedLayout(width: 300, height: 50)) {
    @Previewable @State var value: Double = 0.4
    MEGASliderView(value: $value)
}

@available(iOS 17.0, *)
#Preview(traits: .fixedLayout(width: 300, height: 50)) {
    @Previewable @State var value: Double = 0.4
    MEGASliderView(value: $value)
        .preferredColorScheme(.dark)
}
