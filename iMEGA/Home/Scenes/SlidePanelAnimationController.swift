import UIKit

protocol SlidePanelAnimationControllerDelegate: AnyObject {

    func animateToTopPosition()

    func animateToBottomPosition()

    /// Tell the delegate that the animation progress has updated. The progress is a number between 0 to 1.
    /// - Parameter animationProgress: The animation progress, a number from 0 to 1. 0 means animation starts, and 1
    /// means the animation is finished.
    func didUpdateAnimationProgress(
        _ animationProgress: CGFloat,
        from initialDockingPosition: SlidePanelAnimationController.DockingPosition,
        to targetDockingPosition: SlidePanelAnimationController.DockingPosition
    )
}

final class SlidePanelAnimationController {

    enum DockingPosition {
        case top
        case bottom

        var opposite: DockingPosition {
            switch self {
            case .top: return .bottom
            case .bottom: return .top
            }
        }
    }

    // MARK: - Animation Offset

    var animationOffsetY: CGFloat?

    // MARK: - Animation Progress

    private var animationProgress: CGFloat = 0

    // MARK: - Slide Panel Current Position

    private var currentPosition: DockingPosition = .bottom

    private var transitionAnimator: UIViewPropertyAnimator!

    // MARK: - Delegate

    weak var delegate: SlidePanelAnimationControllerDelegate?

    init(delegate: SlidePanelAnimationControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - Public
    
    func isInTopDockingPosition() -> Bool {
        return currentPosition == .top
    }
    
    func isInBottomDockingPosition() -> Bool {
        return currentPosition == .bottom
    }

    /// It starts animation of slide panel moving towards opposite direction within a duration.
    /// - Parameter duration: The duration for which the animation lasts.
    func animateToOppositeDockingPosition(withDuration duration: TimeInterval) {
        animateTransitionIfNeeded(to: currentPosition.opposite, duration: duration)
    }

    // MARK: - Pan Gesture Controlled Animation

    func startsProgressiveAnimation(withDuration duration: TimeInterval) {
        animateTransitionIfNeeded(to: currentPosition.opposite, duration: duration)
        transitionAnimator.pauseAnimation()
        animationProgress = transitionAnimator.fractionComplete
    }

    func continueAnimation(withVelocityY velocityY: CGFloat, translationY: CGFloat) {
        guard let transitionAnimator = transitionAnimator else {
            return
        }
        
        guard let animationOffsetY = animationOffsetY else {
            fatalError("animationOffsetY in SlidePanelAnimationController must be set.")
        }
        
        let negativeTranslationY = translationY * -1
        var fraction = negativeTranslationY / animationOffsetY
        
        if currentPosition == .top {
            fraction *= -1
        }
        
        if transitionAnimator.isReversed {
            fraction *= -1
        }
        
        transitionAnimator.fractionComplete = fraction
        animationProgress = fraction
        if translationY > 0 {
            delegate?.didUpdateAnimationProgress(animationProgress, from: .top, to: .bottom)
        } else{
            delegate?.didUpdateAnimationProgress(animationProgress, from: .bottom, to: .top)
        }
    }

    func completeAnimation(withVelocityY velocityY: CGFloat) {
        guard let transitionAnimator = transitionAnimator else { return }
        let releasingVelocityGoingDown = velocityY > 0
        let releasingVelocityGoingUp = !releasingVelocityGoingDown

        guard releasingVelocityGoingUp || releasingVelocityGoingDown else {
            transitionAnimator.continueAnimation(withTimingParameters: UISpringTimingParameters(dampingRatio: 0.4), durationFactor: 0)
            return
        }

        transitionAnimator.continueAnimation(withTimingParameters: UICubicTimingParameters(animationCurve: .easeInOut), durationFactor: 0)
    }

    // MARK: - Animation

    private func animateTransitionIfNeeded(to targetPosition: DockingPosition, duration: TimeInterval) {
        transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.6) { [delegate] in
            switch targetPosition {
            case .bottom: delegate?.animateToBottomPosition()
            case .top: delegate?.animateToTopPosition()
            }
        }
        transitionAnimator.addCompletion { [weak self, weak delegate] (position) in
            guard let self = self else { return }

            switch position {
            case .start:
                self.currentPosition = targetPosition.opposite
            case .end:
                self.currentPosition = targetPosition
            case .current:
                break
            @unknown default: break
            }

            self.transitionAnimator = nil
            self.animationProgress = 1
            delegate?.didUpdateAnimationProgress(1, from: targetPosition.opposite, to: targetPosition)
        }
        transitionAnimator.startAnimation()
    }
}
