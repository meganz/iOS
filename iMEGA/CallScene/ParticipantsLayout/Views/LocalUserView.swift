
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

    private var offset: CGPoint = .zero
    private var corner: Corner = .topRight
    private var navigationHidden: Bool = false
    
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
        UIView.animate(withDuration: 0.0) { [weak self] in
            guard let self = self else { return }
            self.center = CGPoint(x: location.x - self.offset.x + self.frame.size.width / 2, y: location.y - self.offset.y + self.frame.size.height / 2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: superview)
        positionView(by: location)
    }

    //MARK: - Public
    func configure(for position: CameraPositionEntity) {
        if !isHidden {
            return
        }
        
        layoutToOrientation()
        videoImageView.transform = (position == .front) ?  CGAffineTransform(scaleX: -1, y: 1) : CGAffineTransform(scaleX: 1, y: 1)
        
        positionView(by: CGPoint(x: UIScreen.main.bounds.size.width, y: 0), animated: false)
        isHidden = false
    }
    
    func configureForFullSize() {
        isUserInteractionEnabled = false
        mutedImageView.isHidden = true
        videoImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        isHidden = false
    }
    
    func updateAvatar(image: UIImage) {
        avatarImageView.image = image
    }
    
    func switchVideo() {
        videoImageView.isHidden = !videoImageView.isHidden
    }
    
    func frameData(width: Int, height: Int, buffer: Data!) {
        videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
    
    func transformLocalVideo(for position: CameraPositionEntity) {
        videoImageView.transform = (position == .front) ?  CGAffineTransform(scaleX: -1, y: 1) : CGAffineTransform(scaleX: 1, y: 1)
    }
    
    func localAudio(enabled: Bool) {
        mutedImageView.isHidden = enabled
    }
    
    func repositionView() {
        layoutToOrientation()
        let point = startingPoint()
        self.center = CGPoint(x: point.x + frame.size.width / 2, y: point.y + frame.size.height / 2)
    }
    
    func updateOffsetWithNavigation(hidden: Bool) {
        navigationHidden = hidden
        positionView(by: center)
    }
    
    func addBlurEffect() {
        addSubview(blurEffectView)
    }
    
    func removeBlurEffect() {
        blurEffectView.removeFromSuperview()
    }
    
    //MARK: - Private
    private func positionView(by center: CGPoint, animated: Bool = true) {
        if animated {
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
            
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }                
                self.center = CGPoint(x: point.x + self.frame.size.width / 2, y: point.y + self.frame.size.height / 2)
            }
        } else {
            let point = startingPoint()
            self.center = CGPoint(x: point.x + frame.size.width / 2, y: point.y + frame.size.height / 2)
        }
    }
    
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
            y = fixedMargin + UIApplication.shared.windows[0].safeAreaInsets.top + (navigationHidden ? 0 : 44)
        case .topRight:
            x = superview.frame.size.width - frame.size.width - fixedMargin - iPhoneXOffset
            y = fixedMargin + UIApplication.shared.windows[0].safeAreaInsets.top  + (navigationHidden ? 0 : 44)
        case .bottomLeft:
            x = fixedMargin + iPhoneXOffset
            y = superview.frame.size.height - frame.size.height - UIApplication.shared.windows[0].safeAreaInsets.bottom - fixedMargin
        case .bottomRight:
            x = superview.frame.size.width - frame.size.width - fixedMargin - iPhoneXOffset
            y = superview.frame.size.height - frame.size.height - UIApplication.shared.windows[0].safeAreaInsets.bottom - fixedMargin
        }
        
        return CGPoint(x: x, y: y)
    }
    
    private func layoutToOrientation() {
        if UIDevice.current.orientation.isLandscape {
            frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: 134, height: 75)
        } else {
            frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: 75, height: 134)
        }
    }
}
