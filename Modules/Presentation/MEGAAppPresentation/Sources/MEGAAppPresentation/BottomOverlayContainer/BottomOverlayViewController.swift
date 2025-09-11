import SwiftUI

/// A base view controller for displaying SwiftUI content while managing bottom overlay insets. This controller implements the common functionality for adjusting the bottom safe area inset.
public class OverlayHostingController<Content: View>: UIHostingController<Content>, BottomOverlayPresenterProtocol, BottomSafeAreaOverlayCoverStatusProviderProtocol {
    
    public var shouldShowSafeAreaOverlayCover: Bool {
        true
    }
    
    public override init(rootView: Content) {
        super.init(rootView: rootView)
    }
    
    @objc required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - BottomOverlayPresenterProtocol
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets.bottom = height
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}

/// A view controller that displays a SwiftUI view along with an audio mini-player overlay. Conforming to AudioPlayerPresenterProtocol, this controller indicates that the mini-player
/// should be visible alongside other bottom overlay elements.
public final class AudioPlayerHostingController<Content: View>: OverlayHostingController<Content>, AudioPlayerPresenterProtocol {}
