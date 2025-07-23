import MEGADesignToken
import SwiftUI
import UIKit

final class MEGASlider: UISlider {
    @IBInspectable var thumbRadius: CGFloat = 10
    @IBInspectable var highlightedThumbRadius: CGFloat = 25
    @IBInspectable var touchExpansion: CGFloat = 20
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        setMinimumTrackImage(customMinimumTrackImage(bgColor: TokenColors.Components.selectionControl), for: .normal)
        maximumTrackTintColor = TokenColors.Background.surface3
        
        setThumbImage(thumbImage(bgColor: TokenColors.Components.selectionControl, radius: thumbRadius), for: .normal)
        setThumbImage(thumbImage(bgColor: TokenColors.Components.selectionControl, radius: highlightedThumbRadius), for: .highlighted)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
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

private struct MEGASliderView: UIViewRepresentable {
    func makeUIView(context: Context) -> MEGASlider {
        MEGASlider(frame: .zero)
    }
    
    func updateUIView(_ uiView: MEGASlider, context: Context) {
        
    }
}

@available(iOS 17.0, *)
#Preview(traits: .fixedLayout(width: 300, height: 50)) {
    MEGASliderView()
}

@available(iOS 17.0, *)
#Preview(traits: .fixedLayout(width: 300, height: 50)) {
    MEGASliderView()
        .preferredColorScheme(.dark)
}
