import UIKit

extension VideoOrientation {
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
