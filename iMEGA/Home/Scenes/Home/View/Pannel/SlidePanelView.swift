import UIKit
import Combine

protocol SlidePanelDelegate: AnyObject {

    func slidePanel(_ panel: SlidePanelView, didBeginPanningWithVelocity: CGPoint)

    func slidePanel(_ panel: SlidePanelView, didStopPanningWithVelocity: CGPoint)

    func slidePanel(_ panel: SlidePanelView, translated: CGPoint, velocity: CGPoint)

    func shouldEnablePanGesture(inSlidePanel slidePanel: SlidePanelView) -> Bool
    
    func shouldEnablePanGestureScrollingUp(inSlidePanel slidePanel: SlidePanelView) -> Bool
    
    func shouldEnablePanGestureScrollingDown(inSlidePanel slidePanel: SlidePanelView) -> Bool
    
    func loadFavourites()
    
    func loadOffline()
}

final class SlidePanelView: UIView, NibOwnerLoadable {

    // MARK: - IBOutlets
    
    @IBOutlet private var handlerView: HandlerView!

    @IBOutlet private var titleView: SegmentTitleView!

    // MARK: - Recents Tab

    @IBOutlet private var recentsContainerView: UIView!
    
    public var recentScrollView: UIScrollView?

    // MARK: - Favourites Tab

    @IBOutlet private var favouritesContainerView: UIView!
    
    public var favouritesScrollView: UIScrollView?
    
    // MARK: - Offlines Tab

    @IBOutlet private var offlineContainerView: UIView!
    
    public var offlineScrollView: UIScrollView?
    
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Tab Control

    private var currentDisplayTab: DisplayTab = .recents {
        didSet {
            switch currentDisplayTab {
            case .recents:
                recentsContainerView.isHidden = false
                favouritesContainerView.isHidden = true
                offlineContainerView.isHidden = true
                
            case .favourites:
                recentsContainerView.isHidden = true
                favouritesContainerView.isHidden = false
                offlineContainerView.isHidden = true
                if favouritesScrollView == nil {
                    delegate?.loadFavourites()
                }
                
            case .offline:
                recentsContainerView.isHidden = true
                favouritesContainerView.isHidden = true
                offlineContainerView.isHidden = false
                if offlineScrollView == nil {
                    delegate?.loadOffline()
                }
            }
        }
    }

    enum DisplayTab: Int {
        case recents
        case favourites
        case offline
    }

    // MARK: - SlidePanelDelegate
    
    weak var delegate: SlidePanelDelegate?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        addRemoveHomeImageFeatureToggleSubscription()
        setupView(with: traitCollection)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNibContent()
        addRemoveHomeImageFeatureToggleSubscription()
        setupView(with: traitCollection)
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
        case .favourites:
            guard let favouritesScrollView = favouritesScrollView else {
                return true
            }
            return favouritesScrollView.contentOffset.y <= 0
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
        recentScrollView = scrollView
        scrollView?.addGestureRecognizer(panGesture)
    }
    
    func addFavouritesViewController(_ favouritesViewController: FavouritesViewController) {
        move(favouritesViewController.view, toContainerView: favouritesContainerView)
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "Favourites Panel Pan Gesture"
        panGesture.addTarget(self, action: #selector(didPan(_:)))
        panGesture.delegate = self

        let scrollView = firstScrollViewInSubviews(favouritesViewController.view.subviews)
        favouritesScrollView = scrollView
        scrollView?.addGestureRecognizer(panGesture)
    }
    
    func addOfflineViewController(_ offlineViewController: OfflineViewController) {
        move(offlineViewController.view, toContainerView: offlineContainerView)
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "Offline Panel Pan Gesture"
        panGesture.addTarget(self, action: #selector(didPan(_:)))
        panGesture.delegate = self

        let scrollView = firstScrollViewInSubviews(offlineViewController.view.subviews)
        offlineScrollView = scrollView
        scrollView?.addGestureRecognizer(panGesture)
    }

    private func move(_ content: UIView, toContainerView container: UIView) {
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.autoPinEdgesToSuperviewEdges()
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
    
    private func addRemoveHomeImageFeatureToggleSubscription() {
        FeatureToggle
            .removeHomeImage
            .$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.setupSegmentTitle()
                self.updateTabVisiblity(to: .recents)
            }
            .store(in: &subscriptions)
    }
    
    
    private func setupView(with trait: UITraitCollection) {
        setupSegmentTitle()
        updateTabVisiblity(to: .recents)
        handlerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(_:))))
        titleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(_:))))
    }

    private func updateTabVisiblity(to tab: DisplayTab) {
        switch currentDisplayTab {
        case .recents:
            recentsContainerView.isHidden = false
            favouritesContainerView.isHidden = true
            offlineContainerView.isHidden = true
            
        case .favourites:
            recentsContainerView.isHidden = true
            offlineContainerView.isHidden = true
            favouritesContainerView.isHidden = false
            
        case .offline:
            recentsContainerView.isHidden = true
            favouritesContainerView.isHidden = true
            offlineContainerView.isHidden = false
        }
    }

    private func setupSegmentTitle() {
        let recentsTitle = Strings.Localizable.recents
        let favouritesTitle = Strings.Localizable.favourites
        let offlineTitle = Strings.Localizable.offline
        
        let segmentModel: SegmentTitleView.SegmentTitleViewModel = FeatureToggle.removeHomeImage.isEnabled ?
                                                                                .init(titles: [.init(text: recentsTitle, index: 0),
                                                                                                .init(text: offlineTitle, index: 1)]) :
                                                                                .init(titles: [.init(text: recentsTitle, index: 0),
                                                                                                .init(text: favouritesTitle, index: 1),
                                                                                                .init(text: offlineTitle, index: 2)])
        titleView.setSegmentTitleViewModel(model: segmentModel)

        titleView.selectAction = { [weak self] title in
            guard let self = self else { return }

            switch title.text {
            case recentsTitle: self.currentDisplayTab = .recents
            case favouritesTitle: self.currentDisplayTab = .favourites
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
