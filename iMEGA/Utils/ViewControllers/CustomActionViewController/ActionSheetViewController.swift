import UIKit

class ActionSheetAction: NSObject {
    @objc var title: String?
    @objc var image: UIImage?
    @objc var action = { }
}

class ActionSheetViewController: UIViewController {

    var layoutThreshold: CGFloat {
        return CGFloat(self.view.bounds.height * 0.3)
    }
    var didSetupConstraints = false
    var tableView = UITableView.newAutoLayout()
    var headerView: UIView?
    var indicator = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 6))
    var backgroundView = UIView.newAutoLayout()
    var top: NSLayoutConstraint?

    @objc var actions: [ActionSheetAction] = []
    @objc var headerTitle: String?

    // MARK: - Private properties
    fileprivate var isPresenting = false

    // MARK: - ActionController initializers

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
    // MARK: - View controller behavior

    override func viewDidLoad() {
        super.viewDidLoad()

        // background view
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActionSheetViewController.tapGestureDidRecognize(_:)))
        backgroundView.addGestureRecognizer(tapRecognizer)
    }

    @objc func tapGestureDidRecognize(_ gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

}

// MARK: PureLayout Implementation
extension ActionSheetViewController {
    override func loadView() {
        super.loadView()
        view.backgroundColor = .clear

        backgroundView.backgroundColor = .init(white: 0, alpha: 0.8)
        view.addSubview(backgroundView)

        headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        headerView?.backgroundColor = .white

        indicator.layer.cornerRadius = 3
        indicator.clipsToBounds = true
        indicator.backgroundColor = UIColor(red: 4/255, green: 4/255, blue: 15/255, alpha: 0.15)
        indicator.isHidden = true
        headerView?.addSubview(indicator)
        indicator.autoAlignAxis(toSuperviewAxis: .vertical)
        indicator.autoSetDimension(.height, toSize: 6)
        indicator.autoSetDimension(.width, toSize: 36)
        indicator.autoPinEdge(toSuperviewEdge: .top, withInset: CGFloat(6))

        let title = UILabel()
        title.text = headerTitle
        title.sizeToFit()
        headerView?.addSubview(title)
        title.autoCenterInSuperview()

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

        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        if !didSetupConstraints {

            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
}

extension ActionSheetViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        var constant = CGFloat()

        let offset = scrollView.panGestureRecognizer.translation(in: view).y
        if offset > 0 {
            print("down")
            if offset > 20 {
                constant = CGFloat(self.view.bounds.height * 0.3)
            }

        } else {
            if abs(offset) > 20 {
                if layoutThreshold > top!.constant {
                    constant = CGFloat(0)
                }
            }

            print("up")
        }
        print(scrollView.panGestureRecognizer.translation(in: view).y)

        top?.constant = constant
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }

    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
        print(scrollView.panGestureRecognizer.translation(in: view).y)

        top?.constant = constant
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }

    }

    open func presentView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
        self.view.layoutIfNeeded()

        var bottomHeight = 0
        if #available(iOS 11.0, *) {
            bottomHeight = Int(view.safeAreaInsets.bottom)
        }
        let height = CGFloat(actions.count * 60 + 70 + bottomHeight)
        if height < view.bounds.height - layoutThreshold {
            top = tableView.autoPinEdge(toSuperviewSafeArea: .top, withInset: CGFloat(view.bounds.height - height))
            tableView.isScrollEnabled = false
            indicator.isHidden = true
        } else {
            top = tableView.autoPinEdge(toSuperviewSafeArea: .top, withInset: layoutThreshold)
            indicator.isHidden = false
        }
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

    open func dismissView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((_ completed: Bool) -> Void)?) {
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
}

extension ActionSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let action = actions[indexPath.row]
        cell.textLabel?.text = action.title
        cell.imageView?.image = action.image
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.dismiss(animated: true, completion: nil)
    }

}

extension ActionSheetViewController: UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let fromView = fromViewController.view

        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let toView = toViewController.view

        if isPresenting {
            toView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            containerView.addSubview(toView!)

            transitionContext.completeTransition(true)
            presentView(toView!, presentingView: fromView!, animationDuration: TimeInterval(0.3), completion: nil)
        } else {
            dismissView(fromView!, presentingView: toView!, animationDuration: TimeInterval(0.3)) { completed in
                if completed {
                    fromView?.removeFromSuperview()
                }
                transitionContext.completeTransition(completed)
            }
        }
    }

    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0 : TimeInterval(0.3)
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
