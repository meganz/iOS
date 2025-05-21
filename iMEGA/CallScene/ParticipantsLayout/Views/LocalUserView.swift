import Foundation
import MEGADomain

enum Corner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

class LocalUserView: UIView {
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var videoImageView: UIImageView!
    @IBOutlet private weak var mutedImageView: UIImageView!
    @IBOutlet private weak var expandImageView: UIImageView!
    @IBOutlet private weak var raisedHandView: UIView!
    @IBOutlet private weak var raiseHandImageView: UIImageView!
    
    private enum Constants {
        static let fixedMargin: CGFloat = 16.0
        static let collapsedViewWidthAndHeight: CGFloat = 46.0
        static let expandedViewWidth: CGFloat = 134.0
        static let expandedViewHeight: CGFloat = 75.0
        static let cornerRadius: CGFloat = 8.0
        static let animationDurations: CGFloat = 0.3
        static let iPhoneXOffset: CGFloat = 30.0
    }
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.layer.cornerRadius = Constants.cornerRadius
        blurEffectView.clipsToBounds = true
        return blurEffectView
    }()

    private var offset: CGPoint = .zero
    private var corner: Corner = .topRight
    private var navigationHidden: Bool = false
    private var isVideoEnabled: Bool = false
    private var isCollapsed: Bool = false

    var expandImage: UIImage? {
        didSet {
            expandImageView.image = expandImage
        }
    }
    
    var mutedImage: UIImage? {
        didSet {
            mutedImageView.image = mutedImage
        }
    }
    
    var raiseHandImage: UIImage? {
        didSet {
            raiseHandImageView.image = raiseHandImage
        }
    }
    
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
            guard let self else { return }
            self.center = CGPoint(x: location.x - self.offset.x + self.frame.size.width / 2, y: location.y - self.offset.y + self.frame.size.height / 2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if touch.tapCount > 0 {
            toggleViewLayout()
        } else {
            let location = touch.location(in: superview)
            positionView(by: location)
        }
    }

    // MARK: - Public
    func configure(for position: CameraPositionEntity) {
        if !isHidden {
            return
        }
        
        frame.size = sizeForView()
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
    
    func switchVideo(to enabled: Bool) {
        isVideoEnabled = enabled
        if isCollapsed {
            return
        }
        avatarImageView.isHidden = isVideoEnabled
        videoImageView.isHidden = !isVideoEnabled
        if !enabled {
            removeBlurEffect()
        }
    }
    
    func frameData(width: Int, height: Int, buffer: Data!) {
        if isCollapsed {
            return
        }
        videoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
    }
    
    func transformLocalVideo(for position: CameraPositionEntity) {
        videoImageView.transform = (position == .front) ?  CGAffineTransform(scaleX: -1, y: 1) : CGAffineTransform(scaleX: 1, y: 1)
    }
    
    func localAudio(enabled: Bool) {
        mutedImageView.isHidden = enabled
    }
    
    func repositionView() {
        frame.size = sizeForView()
        frame.origin = originPointForView()
    }
    
    func updateOffsetWithNavigation(hidden: Bool) {
        navigationHidden = hidden
        positionView(by: center)
    }
    
    func addBlurEffect() {
        if isCollapsed {
            return
        }
        blurEffectView.frame.size = sizeForView()
        addSubview(blurEffectView)
    }
    
    func removeBlurEffect() {
        if isCollapsed {
            return
        }
        blurEffectView.removeFromSuperview()
    }
    
    func raisedHandHidden(_ hidden: Bool) {
        raisedHandView.isHidden = hidden
    }
    
    // MARK: - Private
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
            
            UIView.animate(withDuration: Constants.animationDurations) { [weak self] in
                guard let self else { return }
                self.frame.origin = self.originPointForView()
            }
        } else {
            frame.origin = originPointForView()
        }
    }
    
    private func originPointForView() -> CGPoint {
        guard let superview else { return .zero }
        var iPhoneXOffset: CGFloat = 0.0
        
        if UIDevice.current.iPhoneX && UIScreen.main.bounds.size.height < UIScreen.main.bounds.size.width {
            iPhoneXOffset = Constants.iPhoneXOffset
        }
        
        let superviewWidth = superview.frame.size.width
        let superviewHeight = superview.frame.size.height
        let topInset = (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)
        let bottomInset = (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
        
        switch corner {
        case .topLeft:
            return CGPoint(x: Constants.fixedMargin + iPhoneXOffset,
                           y: Constants.fixedMargin + topInset + (navigationHidden ? 0 : 44))
        case .topRight:
            return CGPoint(x: superviewWidth - frame.size.width - Constants.fixedMargin - iPhoneXOffset,
                           y: Constants.fixedMargin + topInset + (navigationHidden ? 0 : 44))
        case .bottomLeft:
            return CGPoint(x: Constants.fixedMargin + iPhoneXOffset,
                           y: superviewHeight - frame.size.height - bottomInset - Constants.fixedMargin)
        case .bottomRight:
            return CGPoint(x: superviewWidth - frame.size.width - Constants.fixedMargin - iPhoneXOffset,
                           y: superviewHeight - frame.size.height - bottomInset - Constants.fixedMargin)
        }
    }
    
    private func sizeForView() -> CGSize {
        if isCollapsed {
            return CGSize(width: Constants.collapsedViewWidthAndHeight, height: Constants.collapsedViewWidthAndHeight)
        } else if UIDevice.current.orientation.isLandscape {
            return CGSize(width: Constants.expandedViewWidth, height: Constants.expandedViewHeight)
        } else {
            return CGSize(width: Constants.expandedViewHeight, height: Constants.expandedViewWidth)
        }
    }
    
    private func toggleViewLayout() {
        isCollapsed.toggle()
        UIView.animate(withDuration: Constants.animationDurations) { [weak self] in
            guard let self else { return }
            self.frame.size = self.sizeForView()
            self.frame.origin = self.originPointForView()
            self.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self else { return }
            self.expandImageView.isHidden = !self.isCollapsed
            self.avatarImageView.isHidden = self.isCollapsed ? true : self.isVideoEnabled
            self.videoImageView.isHidden = self.isCollapsed ? true : !self.isVideoEnabled
        }
    }
}
