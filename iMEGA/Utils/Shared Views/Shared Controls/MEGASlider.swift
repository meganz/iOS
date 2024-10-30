import MEGADesignToken
import SwiftUI
import UIKit

final class MEGASlider: UISlider {
    @IBInspectable var thumbRadius: CGFloat = 10
    @IBInspectable var hightlitedThumbRadius: CGFloat = 25
    
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
    }
    
    private func configure() {
        setMinimumTrackImage(customMinimumTrackImage(bgColor: TokenColors.Components.interactive), for: .normal)
        maximumTrackTintColor = TokenColors.Background.surface2
        
        setThumbImage(thumbImage(bgColor: TokenColors.Components.interactive, radius: thumbRadius), for: .normal)
        setThumbImage(thumbImage(bgColor: TokenColors.Components.interactive, radius: hightlitedThumbRadius), for: .highlighted)
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
}

private struct MEGASliderView: UIViewRepresentable {
    func makeUIView(context: Context) -> MEGASlider {
        return MEGASlider(frame: .zero)
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
