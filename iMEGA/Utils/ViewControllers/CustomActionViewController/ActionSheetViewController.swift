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
    }

    @objc func tapGestureDidRecognize(_ gesture: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
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

            tableView.autoPinEdge(toSuperviewEdge: .bottom)
            tableView.autoPinEdge(toSuperviewEdge: .left)
            tableView.autoPinEdge(toSuperviewEdge: .right)

            let height = CGFloat(actions.count * 60 + 50 + bottomHeight)
            if height < 200 {
                top = tableView.autoSetDimension(.height, toSize: height)
            } else {
                top = tableView.autoPinEdge(toSuperviewSafeArea: .top, withInset: view.bounds.height * 0.5)
            }
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
                constant = CGFloat(self.view.bounds.height * 0.5)
            }

        } else {
            if abs(offset) > 20 {
                if CGFloat(view.bounds.height * 0.5) > top!.constant {
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
            print("down")
            if offset > 20 {
                if CGFloat(view.bounds.height * 0.5) < top!.constant {
                    dismiss(animated: true, completion: nil)
                    return
                } else {
                    constant = CGFloat(self.view.bounds.height * 0.5)

                }
            }
        } else {
            if abs(offset) > 20 {
                if CGFloat(view.bounds.height * 0.5) > top!.constant {
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
}

extension ActionSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
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
