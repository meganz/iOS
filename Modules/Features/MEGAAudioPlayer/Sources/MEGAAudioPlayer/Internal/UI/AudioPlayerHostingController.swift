import MEGADesignToken
import SwiftUI
import UIKit

/// Hosts the SwiftUI audio player and adds an interactive swipe-down-to-dismiss.
final class AudioPlayerHostingController: UIHostingController<AudioPlayerView> {

    var isPlaylistVisible: () -> Bool = { false }

    private let dismissDistanceThreshold: CGFloat = 120
    private let dismissVelocityThreshold: CGFloat = 900

    var playlistListTopY: () -> CGFloat = { 0 }

    private let draggedCornerRadius: CGFloat = TokenRadius.extraLarge

    override func viewDidLoad() {
        super.viewDidLoad()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }

    @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
        let translationY = max(0, gesture.translation(in: view).y)

        switch gesture.state {
        case .changed:
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            view.layer.transform = CATransform3DMakeTranslation(0, translationY, 0)
            view.layer.cornerRadius = translationY > 0 ? draggedCornerRadius : 0
            CATransaction.commit()

        case .ended, .cancelled:
            let velocityY = gesture.velocity(in: view).y
            let committed = gesture.state == .ended
                && translationY > 0
                && (translationY > dismissDistanceThreshold || velocityY > dismissVelocityThreshold)

            if committed {
                let remaining = max(view.bounds.height - translationY, 1)
                let duration = min(0.3, max(0.12, TimeInterval(remaining / max(velocityY, 600))))
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                    self.view.layer.transform = CATransform3DMakeTranslation(0, self.view.bounds.height, 0)
                } completion: { _ in
                    self.dismiss(animated: false)
                }
            } else {
                UIView.animate(
                    withDuration: 0.35,
                    delay: 0,
                    usingSpringWithDamping: 0.85,
                    initialSpringVelocity: 0.4,
                    options: .curveEaseOut
                ) {
                    self.view.layer.transform = CATransform3DIdentity
                    self.view.layer.cornerRadius = 0
                }
            }

        default:
            break
        }
    }
}

extension AudioPlayerHostingController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: view)
        guard velocity.y > 0, velocity.y > abs(velocity.x) else { return false }
        if isPlaylistVisible() {
            return pan.location(in: view).y < playlistListTopY()
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
