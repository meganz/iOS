import Combine
import MEGADesignToken
import MEGAL10n
import UIKit

protocol SlidePanelDelegate: AnyObject {
    
    func slidePanel(_ panel: SlidePanelView, didBeginPanningWithVelocity: CGPoint)
    
    func slidePanel(_ panel: SlidePanelView, didStopPanningWithVelocity: CGPoint)
    
    func slidePanel(_ panel: SlidePanelView, translated: CGPoint, velocity: CGPoint)
    
    func shouldEnablePanGesture(inSlidePanel slidePanel: SlidePanelView) -> Bool
    
    func shouldEnablePanGestureScrollingUp(inSlidePanel slidePanel: SlidePanelView) -> Bool
    
    func shouldEnablePanGestureScrollingDown(inSlidePanel slidePanel: SlidePanelView) -> Bool
    
    func offlineTabSelected(isFirstLoad: Bool)
}

final class SlidePanelView: UIView, NibOwnerLoadable {
    
    // MARK: - IBOutlets
    
    @IBOutlet private var handlerView: HandlerView!
    
    @IBOutlet private var titleView: SegmentTitleView!
    
    // MARK: - Recents Tab
    
    @IBOutlet private var recentsContainerView: UIView!
    
    public var recentScrollView: UIScrollView?
    
    // MARK: - Offlines Tab
    
    @IBOutlet private var offlineContainerView: UIView!
    
    public var offlineScrollView: UIScrollView?

    // MARK: - Tab Control
    
    private var currentDisplayTab: DisplayTab = .recents {
        didSet {
            switch currentDisplayTab {
            case .recents:
                recentsContainerView.isHidden = false
                offlineContainerView.isHidden = true
                
            case .offline:
                recentsContainerView.isHidden = true
                offlineContainerView.isHidden = false
                delegate?.offlineTabSelected(isFirstLoad: offlineScrollView == nil)
            }
        }
    }
    
    enum DisplayTab: Int {
        case recents
        case offline
    }
    
    // MARK: - SlidePanelDelegate
    
    weak var delegate: (any SlidePanelDelegate)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadNibContent()
        setupView()
    }
    
    // MARK: - Switch Tab
    
    func showTab(_ tab: DisplayTab) {
        currentDisplayTab = tab
        titleView.selectTab(currentDisplayTab.rawValue)
    }
    
    func isOverScroll() -> Bool {
        switch currentDisplayTab {
        case .offline:
            guard let offlineScrollView = offlineScrollView else {
                return true
            }
            return offlineScrollView.contentOffset.y <= 0

        case .recents:
            guard let recentScrollView = recentScrollView else {
                return true
            }
            return recentScrollView.contentOffset.y <= 0
        }
    }
    
    // MARK: - Add ViewControllers to Slide Panel
    
    func addRecentsViewController(_ recentViewController: RecentsViewController) {
        move(recentViewController.view, toContainerView: recentsContainerView)
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "Recents Panel Pan Gesture"
        panGesture.addTarget(self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let scrollView = firstScrollViewInSubviews(recentViewController.view.subviews)
        scrollView?.backgroundColor = TokenColors.Background.page
        recentScrollView = scrollView
        scrollView?.addGestureRecognizer(panGesture)
    }
        
    func addOfflineViewController(_ offlineViewController: OfflineViewController) {
        move(offlineViewController.view, toContainerView: offlineContainerView)
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "Offline Panel Pan Gesture"
        panGesture.addTarget(self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let scrollView = firstScrollViewInSubviews(offlineViewController.view.subviews)
        scrollView?.backgroundColor = TokenColors.Background.page
        offlineScrollView = scrollView
        scrollView?.addGestureRecognizer(panGesture)
    }
    
    private func move(_ content: UIView, toContainerView container: UIView) {
        container.wrap(content)
    }
    
    private func firstScrollViewInSubviews(_ subviews: [UIView]) -> UIScrollView? {
        for subview in subviews where subview is UIScrollView {
            return subview as? UIScrollView
        }
        
        for subview in subviews {
            let foundFirstScrollView = firstScrollViewInSubviews(subview.subviews)
            if foundFirstScrollView != nil {
                return foundFirstScrollView
            }
        }
        return nil
    }
    
    // MARK: - Privates
    
    private func setupView() {
        setupSegmentTitle()
        updateTabVisiblity(to: .recents)
        
        handlerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(_:))))
        titleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(_:))))
        
        handlerView.backgroundColor = TokenColors.Background.page
        titleView.backgroundColor = TokenColors.Background.page
    }
    
    private func updateTabVisiblity(to tab: DisplayTab) {
        switch currentDisplayTab {
        case .recents:
            recentsContainerView.isHidden = false
            offlineContainerView.isHidden = true
            
        case .offline:
            recentsContainerView.isHidden = true
            offlineContainerView.isHidden = false
        }
    }
    
    private func setupSegmentTitle() {
        let recentsTitle = Strings.Localizable.recents
        let offlineTitle = Strings.Localizable.offline
        
        let segmentModel: SegmentTitleView.SegmentTitleViewModel = .init(titles: [.init(text: recentsTitle, index: 0),
                                                                                  .init(text: offlineTitle, index: 1)])
        titleView.setSegmentTitleViewModel(model: segmentModel)
        
        titleView.selectAction = { [weak self] title in
            guard let self else { return }
            
            switch title.text {
            case recentsTitle: self.currentDisplayTab = .recents
            case offlineTitle: self.currentDisplayTab = .offline
            default: fatalError()
            }
        }
    }
    
    // MARK: - Handling UIScrollView's pan gesture to slide the panel view
    
    @objc private func didPan(_ gesture: UIPanGestureRecognizer) {
        processGesture(gesture)
    }
    
    private func processGesture(_ gesture: UIPanGestureRecognizer) {
        guard let delegate = delegate else { return }
        let velocity = gesture.velocity(in: gesture.view)
        let directionUp = velocity.y < 0
        
        if directionUp {
            if delegate.shouldEnablePanGestureScrollingUp(inSlidePanel: self)
                // if delegate says scrolling up is not allowed, that is because the delegate does not know
                // the slide panel is actually dragging by the gesture. So here if `gesture.state != began` is omitted,
                // the panel only supports one direction and can not drag to the opposite direction while dragging.
                // By adding `gesture.state != .began`, only `dragging up when in top position` and `dragging down when
                // in bottom position` being omitted whichi is correct.
                || gesture.state != .began {
                processScrollingUpGesture(
                    withVelocity: velocity,
                    state: gesture.state,
                    translation: gesture.translation(in: gesture.view)
                )
            }
            return
        }
        
        let directionDown = !directionUp
        if directionDown {
            if delegate.shouldEnablePanGestureScrollingDown(inSlidePanel: self) || gesture.state != .began {
                processScrollingDownGesture(
                    withVelocity: velocity,
                    state: gesture.state,
                    translation: gesture.translation(in: gesture.view)
                )
                return
            }
        }
    }
    
    private func processScrollingUpGesture(
        withVelocity velocity: CGPoint,
        state: UIGestureRecognizer.State,
        translation: CGPoint
    ) {
        switch state {
        case .began:    delegate?.slidePanel(self, didBeginPanningWithVelocity: velocity)
        case .changed:  delegate?.slidePanel(self, translated: translation, velocity: velocity)
        case .ended:    delegate?.slidePanel(self, didStopPanningWithVelocity: velocity)
        default:
            break
        }
    }
    
    private func processScrollingDownGesture(
        withVelocity velocity: CGPoint,
        state: UIGestureRecognizer.State,
        translation: CGPoint
    ) {
        switch state {
        case .began:    delegate?.slidePanel(self, didBeginPanningWithVelocity: velocity)
        case .changed:  delegate?.slidePanel(self, translated: translation, velocity: velocity)
        case .ended:    delegate?.slidePanel(self, didStopPanningWithVelocity: velocity)
        default:
            break
        }
    }
}

extension SlidePanelView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let delegate = delegate else { fatalError() }
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { fatalError() }
        let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view)
        let scrollingUp = velocity.y < 0
        let scrollingDown = !scrollingUp
        if scrollingUp && delegate.shouldEnablePanGestureScrollingUp(inSlidePanel: self) {
            return false // `false` makes only recognize the pan gesture only
        }
        
        if scrollingDown && delegate.shouldEnablePanGestureScrollingDown(inSlidePanel: self) {
            return false // `false` makes only recognize the pan gesture only
        }
        
        return true // `true` makes only recognize the scroll view and pan
    }
}
