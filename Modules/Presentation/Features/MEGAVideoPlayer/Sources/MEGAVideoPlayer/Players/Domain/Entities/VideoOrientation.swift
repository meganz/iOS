import UIKit

public enum VideoOrientation: String, CaseIterable, Sendable {
    case portrait
    case landscape
    
    /// Toggle to the next orientation
    public func toggled() -> VideoOrientation {
        switch self {
        case .portrait: .landscape
        case .landscape: .portrait
        }
    }

    func toUIInterfaceOrientation() -> UIInterfaceOrientation {
        switch self {
        case .portrait: .portrait
        case .landscape: .landscapeRight
        }
    }
}

extension UIDeviceOrientation {
    func toVideoOrientation(_ currentVideoOrientation: VideoOrientation) -> VideoOrientation {
        switch self {
        case .landscapeLeft, .landscapeRight: .landscape
        case .portrait, .portraitUpsideDown: .portrait
        default: currentVideoOrientation
        }
    }
}
