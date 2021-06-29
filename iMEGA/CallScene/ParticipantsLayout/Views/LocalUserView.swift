
import Foundation

enum Corner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

let fixedMargin: CGFloat = 16.0

class LocalUserView: UIView {
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var videoImageView: UIImageView!
    @IBOutlet private weak var mutedImageView: UIImageView!

    private lazy var blurEffectView : UIVisualEffectView = {
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = 8
        blurEffectView.clipsToBounds = true
        return blurEffectView
    }()

    var offset: CGPoint = .zero
    var corner: Corner = .topRight
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        offset = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: superview)
        UIView.beginAnimations("Dragging", context: nil)
        center = CGPoint(x: location.x - offset.x + frame.size.width / 2, y: location.y - offset.y + frame.size.height / 2)
        UIView.commitAnimations()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: superview)
        positionView(by: location)
    }

    //MARK: - Public
    func configure() {
        if !isHidden {
            return
        }
        videoImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        avatarImageView.mnz_setImage(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ?? MEGAInvalidHandle)
        
        positionView(by: CGPoint(x: UIScreen.main.bounds.size.width, y: 0), animated: false)
        isHidden = false
    }
    
    func switchVideo() {
        videoImageView.isHidden = !videoImageView.isHidden
    }
    
    func frameData(width: Int, height: Int, buffer: Data!) {
        videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
    
    func transformLocalVideo(for position: CameraPosition) {
        addSubview(blurEffectView)
        
        videoImageView.transform = (position == .front) ?  CGAffineTransform(scaleX: -1, y: 1) : CGAffineTransform(scaleX: 1, y: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.blurEffectView.removeFromSuperview()
        }
    }
    
    public func localAudio(enabled: Bool) {
        mutedImageView.isHidden = enabled
    }
    
    func positionView(by center: CGPoint, animated: Bool = true) {
        if animated {
            UIView.beginAnimations("Dragging", context: nil)

            guard let superview = superview else { return }
            if center.x > superview.frame.size.width / 2 {
                if center.y > superview.frame.size.height / 2 {
                    corner = .bottomRight
                } else {
                    corner = .topRight
                }
            } else {
                if center.y > superview.frame.size.height / 2 {
                    corner = .bottomLeft
                } else {
                    corner = .topLeft
                }
            }
            let point = startingPoint()
            self.center = CGPoint(x: point.x + frame.size.width / 2, y: point.y + frame.size.height / 2)
            UIView.commitAnimations()
        } else {
            let point = startingPoint()
            self.center = CGPoint(x: point.x + frame.size.width / 2, y: point.y + frame.size.height / 2)
        }
    }
    
    func repositionView() {
        let point = startingPoint()
        self.center = CGPoint(x: point.x + frame.size.width / 2, y: point.y + frame.size.height / 2)
    }
    
    //MARK: - Private
    private func startingPoint() -> CGPoint {
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        var iPhoneXOffset: CGFloat = 0.0
        
        if UIDevice.current.iPhoneX && UIScreen.main.bounds.size.height < UIScreen.main.bounds.size.width {
            iPhoneXOffset = 30.0
        }
        guard let superview = superview else { return .zero }

        switch corner {
        case .topLeft:
            x = fixedMargin + iPhoneXOffset
            y = fixedMargin + UIApplication.shared.windows[0].safeAreaInsets.top
        case .topRight:
            x = superview.frame.size.width - frame.size.width - fixedMargin - iPhoneXOffset
            y = fixedMargin + UIApplication.shared.windows[0].safeAreaInsets.top
        case .bottomLeft:
            x = fixedMargin + iPhoneXOffset
            y = superview.frame.size.height - frame.size.height - UIApplication.shared.windows[0].safeAreaInsets.bottom
        case .bottomRight:
            x = superview.frame.size.width - frame.size.width - fixedMargin - iPhoneXOffset
            y = superview.frame.size.height - frame.size.height - UIApplication.shared.windows[0].safeAreaInsets.bottom
        }
        
        return CGPoint(x: x, y: y)
    }
    
}
