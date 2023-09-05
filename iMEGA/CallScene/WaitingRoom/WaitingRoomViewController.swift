import MEGAL10n
import MEGAUIKit
import SwiftUI

final class WaitingRoomViewController: UIViewController {
    lazy var leaveBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.Meetings.WaitingRoom.leave,
                                                                    style: .plain,
                                                                    target: self,
                                                                    action: #selector(leaveButtonItemTapped))
    
    lazy var infoBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.Meetings.infoMeetings.image,
                                                                  style: .plain,
                                                                  target: self,
                                                                  action: #selector(infoButtonItemTapped))
    
    private(set) var viewModel: WaitingRoomViewModel

    lazy var hostingView = UIHostingController(rootView: WaitingRoomView(viewModel: viewModel))

    init(viewModel: WaitingRoomViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBarTitle()
        configureNavBarItems()
        configureSubview()
    }
    
    @objc func infoButtonItemTapped() {
        viewModel.infoButtonTapped()
    }
    
    @objc func leaveButtonItemTapped() {
        viewModel.leaveButtonTapped()
    }
    
    // MARK: - Private
    
    private func configureNavBarTitle() {
        navigationItem.titleView = UILabel().customNavBarLabel(
            title: viewModel.meetingTitle,
            titleFont: UIFont.preferredFont(style: .subheadline, weight: .bold),
            subtitle: viewModel.createMeetingDate(),
            subtitleFont: UIFont.preferredFont(style: .caption1, weight: .regular)
        )
        navigationItem.titleView?.sizeToFit()
    }
    
    private func configureNavBarItems() {
        leaveBarButtonItem.setTitleTextAttributes([.foregroundColor: Colors.General.Gray.d1D1D1.color], for: .normal)
        navigationItem.leftBarButtonItem = leaveBarButtonItem
        navigationItem.rightBarButtonItem = infoBarButtonItem
    }
    
    private func configureSubview() {
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func forceNavigationBarUpdate() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }
}

// MARK: - TraitEnvironmentAware

extension WaitingRoomViewController: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        forceNavigationBarUpdate()
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        forceNavigationBarUpdate()
    }
}
