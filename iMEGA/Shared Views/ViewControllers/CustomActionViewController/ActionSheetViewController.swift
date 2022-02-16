import UIKit
import PureLayout

class ActionSheetViewController: UIViewController {

    var tableView = UITableView.newAutoLayout()
    var headerView: UIView?

    var actions: [BaseAction] = []
    var headerTitle: String?
    var dismissCompletion: (() -> Void)?

    // MARK: - Private properties
    private var isPresenting = false
    private var indicator = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 6))
    private var backgroundView = UIView.newAutoLayout()
    private var top: NSLayoutConstraint?
    private var layoutThreshold: CGFloat { self.view.bounds.height * CGFloat(0.3) }
    private let titleLabel = UILabel()

    // MARK: - ActionController initializers

    @objc convenience init(actions: [BaseAction], headerTitle: String?, dismissCompletion: (() -> Void)?, sender: Any?) {
        self.init(nibName: nil, bundle: nil)
        
        self.actions = actions
        self.headerTitle = headerTitle
        self.dismissCompletion = dismissCompletion

        configurePresentationStyle(from: sender as Any)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View controller behavior

    override func viewDidLoad() {
        super.viewDidLoad()

        // background view
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActionSheetViewController.tapGestureDidRecognize(_:)))
        backgroundView.addGestureRecognizer(tapRecognizer)
        
        configureActionTableView()
    }
    
    func configurePresentationStyle(from sender: Any) {
        if UIDevice.current.iPadDevice && !UIApplication.shared.isSplitOrSlideOver && (sender is UIBarButtonItem || sender is UIView) {
            modalPresentationStyle = .popover
            popoverPresentationController?.delegate = self
            popoverPresentationController?.permittedArrowDirections = .any
            if let barButtonSender = sender as? UIBarButtonItem {
                popoverPresentationController?.barButtonItem = barButtonSender
            } else if let viewSender = sender as? UIView {
                popoverPresentationController?.sourceView = viewSender
                popoverPresentationController?.sourceRect = viewSender.bounds
            }
        } else {
            transitioningDelegate = self
            modalPresentationStyle = .custom
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard UIDevice.current.iPhoneDevice else {
            return
        }
        layoutViews(to: size)
        UIView.animate(withDuration: 0.2,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
            },
                       completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    func updateAppearance() {
        tableView.backgroundColor = .mnz_backgroundElevated(traitCollection)
        titleLabel.textColor = UIColor.mnz_label()
        indicator.backgroundColor = UIColor.mnz_handlebar(for: traitCollection)
    }
    
    func layoutViews(to size: CGSize) {
        let headerHeight: CGFloat = headerView?.bounds.height ?? CGFloat.zero
        configViews(withSize: size, height: actionHeight() + headerHeight)
    }
    
    private func actionHeight() -> CGFloat {
        let bottomHeight: CGFloat = view.safeAreaInsets.bottom * CGFloat(2.0)
        let actionCount: CGFloat = CGFloat(actions.count) * CGFloat(60.0)
        return actionCount + bottomHeight + CGFloat(20.0)
    }
    
    private func configViews(withSize size: CGSize, height: CGFloat) {
        let threshold = size.height * CGFloat(0.3)
        if height < size.height - threshold {
            top?.constant = size.height - height
            tableView.isScrollEnabled = false
            indicator.isHidden = true
        } else {
            top?.constant = threshold
            tableView.isScrollEnabled = true
            indicator.isHidden = false
        }
    }
    
    @objc func tapGestureDidRecognize(_ gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true) { [weak self] in
            self?.dismissCompletion?()
        }
    }
    
    func presentView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
        view.layoutIfNeeded()
        
        layoutViews(to: view.frame.size)
        backgroundView.alpha = 0
        
        UIView.animate(withDuration: animationDuration,
                       animations: { [weak self] in
                        self?.backgroundView.alpha = 1.0
                        self?.view.layoutIfNeeded()
                        
            },
                       completion: { finished in
                        completion?(finished)
        })
    }
    
    func dismissView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
        top?.constant = CGFloat(view.bounds.height)
        UIView.animate(withDuration: animationDuration,
                       animations: { [weak self] in
                        self?.backgroundView.alpha = 0
                        self?.view.layoutIfNeeded()
                        
            },
                       completion: { _ in
                        completion?(true)
        })
    }
    
    @objc func update(actions: [BaseAction], sender: Any?) {
        guard let sender = sender else { return }
        
        self.actions = actions
        
        UIView.performWithoutAnimation { [weak self] in
            self?.configurePresentationStyle(from: sender)
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - Private functions
    
    private func configureActionTableView() {
        tableView.register(UINib(nibName: String(describing: ActionSheetSwitchCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ActionSheetSwitchCell.self))
    }
}

// MARK: PureLayout Implementation
extension ActionSheetViewController {
    override func loadView() {
        super.loadView()
        view.backgroundColor = .clear

        backgroundView.backgroundColor = .init(white: 0, alpha: 0.4)
        view.addSubview(backgroundView)

        indicator.layer.cornerRadius = 3
        indicator.clipsToBounds = true
        indicator.isHidden = true
        if headerView == nil {
            headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        }
        headerView?.addSubview(indicator)
        indicator.autoAlignAxis(toSuperviewAxis: .vertical)
        indicator.autoSetDimension(.height, toSize: 6)
        indicator.autoSetDimension(.width, toSize: 36)
        indicator.autoPinEdge(toSuperviewEdge: .top, withInset: CGFloat(6))

        titleLabel.text = headerTitle
        titleLabel.font = .preferredFont(style: .subheadline, weight: .medium)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.sizeToFit()
        headerView?.addSubview(titleLabel)
        titleLabel.autoCenterInSuperview()

        if headerTitle == nil {
            headerView?.frame = CGRect(x: 0, y: 0, width: 320, height: 10)
        }
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = true
        tableView.layer.cornerRadius = 16
        view.addSubview(tableView)

        backgroundView.autoPinEdgesToSuperviewEdges()

        tableView.autoPinEdge(toSuperviewEdge: .bottom)
        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        top = tableView.autoPinEdge(toSuperviewSafeArea: .top, withInset: CGFloat(view.bounds.height))
    }
}

extension ActionSheetViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard modalPresentationStyle != .popover else {
            return
        }
        if scrollView.contentOffset.y <= 0 {
            top?.constant = max(top!.constant - scrollView.contentOffset.y, 0)
            scrollView.setContentOffset(.zero, animated: false)

        } else {
            if top?.constant != 0 {
                top?.constant = max(top!.constant - scrollView.contentOffset.y, 0)
                scrollView.setContentOffset(.zero, animated: false)
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard modalPresentationStyle != .popover else {
            return
        }
        var constant = CGFloat()

        let offset = scrollView.panGestureRecognizer.translation(in: view).y
        if offset > 0 {
            if offset > 20 {
                constant = CGFloat(self.view.bounds.height * 0.3)
            }

        } else {
            if abs(offset) > 20 {
                if layoutThreshold > top!.constant {
                    constant = CGFloat(0)
                }
            }
        }

        top?.constant = constant
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard modalPresentationStyle != .popover else {
            return
        }
        var constant = CGFloat()
        if decelerate {
            return
        }
        let offset = scrollView.panGestureRecognizer.translation(in: view).y
        if offset > 0 {
            if offset > 20 {
                if layoutThreshold < top!.constant {
                    self.dismiss(animated: true, completion: nil)
                    return
                } else {
                    constant = CGFloat(self.view.bounds.height * 0.3)

                }
            }
        } else {
            if abs(offset) > 20 {
                if layoutThreshold > top!.constant {
                    constant = CGFloat(0)
                }
            }
        }

        top?.constant = constant
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }

    }
}

extension ActionSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let action = actions[indexPath.row] as? ActionSheetSwitchAction {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ActionSheetSwitchCell.self),
                                                           for: indexPath) as? ActionSheetSwitchCell else {
                fatalError("could not dequeue the ActionSheetSwitchCell cell")
            }
            
            cell.configureCell(action: action)
            
            return cell
        } else {
            let cell: ActionSheetCell = tableView.dequeueReusableCell(withIdentifier:"ActionSheetCell") as? ActionSheetCell ?? ActionSheetCell(style: .value1, reuseIdentifier: "ActionSheetCell")
            cell.configureCell(action: actions[indexPath.row] )

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let action = actions[indexPath.row] as? ActionSheetAction else {
            return
        }
        
        if action.isKind(of: ActionSheetSwitchAction.self) {
            action.actionHandler()
        } else {
            dismiss(animated: true, completion: {
                action.actionHandler()
            })
        }
    }

}

extension ActionSheetViewController: UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let fromView = fromViewController.view,
            let toView = toViewController.view
            else {
                return
        }
        
        if isPresenting {
            toView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            containerView.addSubview(toView)

            transitionContext.completeTransition(true)
            presentView(toView, presentingView: fromView, animationDuration: TimeInterval(0.2), completion: nil)
        } else {
            dismissView(fromView, presentingView: toView, animationDuration: TimeInterval(0.2)) { completed in
                if completed {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(completed)
            }
        }
    }

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0 : TimeInterval(0.2)
    }

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
}

extension ActionSheetViewController: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        let height = CGFloat(actions.count * 60) + (headerView?.bounds.height ?? 0)
        top?.constant = 0.0
        backgroundView.backgroundColor = .clear
        preferredContentSize = CGSize(width: 320, height: height)
    }
}
