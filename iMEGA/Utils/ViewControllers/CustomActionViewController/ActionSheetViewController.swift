import UIKit

class ActionSheetAction: NSObject {
    @objc var title: String?
    @objc var image: UIImage?
    @objc var action = { }
}

class ActionSheetViewController: UIViewController {

    var didSetupConstraints = false
    var tableView = UITableView.newAutoLayout()
    var headerView: UIView?
    var backgroundView = UIView.newAutoLayout()
    var top: NSLayoutConstraint?
    
    @objc var actions: [ActionSheetAction] = []
    @objc var headerTitle: String?

    // MARK: - View controller behavior

    override func viewDidLoad() {
        super.viewDidLoad()

        // background view
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ActionSheetViewController.tapGestureDidRecognize(_:)))
        backgroundView.addGestureRecognizer(tapRecognizer)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ActionSheetViewController.dragViewMoved(_:)))
        view.addGestureRecognizer(panGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let cornerLayer = CAShapeLayer()
        cornerLayer.frame = tableView.bounds
        let path = UIBezierPath(roundedRect: tableView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 20, height: 20)).cgPath
        cornerLayer.path = path

    }

    @objc func tapGestureDidRecognize(_ gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dragViewMoved(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let translation = gesture.translation(in: tableView)
            top?.constant = max(top!.constant + translation.y, 0)
            if Int(top!.constant) <= 0 {
                tableView.isScrollEnabled = true
            }
            gesture.setTranslation(.zero, in: view)
        }
    }

}

// MARK: PureLayout Implementation
extension ActionSheetViewController {
    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear

        backgroundView.backgroundColor = .init(white: 0, alpha: 0.8)
        view.addSubview(backgroundView)

        headerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        headerView?.backgroundColor = .white

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
  
        view.addSubview(tableView)
        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        if !didSetupConstraints {

            backgroundView.autoPinEdgesToSuperviewEdges()

            var bottomHeight = 0
            if #available(iOS 11.0, *) {
                bottomHeight = Int(view.safeAreaInsets.bottom)
            }
            
            let height = CGFloat(actions.count * 60 + 50 + bottomHeight)
            if height < 200 {
                top = tableView.autoSetDimension(.height, toSize: height)
                tableView.autoPinEdge(toSuperviewEdge: .bottom)
                tableView.autoPinEdge(toSuperviewSafeArea: .left)
                tableView.autoPinEdge(toSuperviewSafeArea: .right)
            } else {
                top = tableView.autoPinEdge(.top, to: .top, of: view, withOffset: 200)
                tableView.autoPinEdge(toSuperviewEdge: .left)
                tableView.autoPinEdge(toSuperviewEdge: .bottom)
                tableView.autoPinEdge(toSuperviewEdge: .right)
            }
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
}

extension ActionSheetViewController: UITableViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        top?.constant = max(top!.constant + actualPosition.y, 0)

        if actualPosition.y > 0 {
            // Dragging down
//                top?.constant = max(top!.constant + actualPosition.y, 0)
        } else {
            // Dragging up
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset.y)
        if scrollView.contentOffset.y < 0 {
            top?.constant = max(top!.constant - scrollView.contentOffset.y, 0)

        }

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
