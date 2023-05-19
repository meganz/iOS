import UIKit

final class MEGASlider: UISlider {
    @IBInspectable var thumbRadius: CGFloat = 10
    @IBInspectable var hightlitedThumbRadius: CGFloat = 25
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        minimumTrackTintColor = .mnz_green00A886()
        maximumTrackTintColor = UIColor.mnz_gray848484().withAlphaComponent(0.3)

        setThumbImage(thumbImage(bgColor: .mnz_green00A886(), radius: thumbRadius), for: .normal)
        setThumbImage(thumbImage(bgColor: .mnz_green00A886(), radius: hightlitedThumbRadius), for: .highlighted)
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
