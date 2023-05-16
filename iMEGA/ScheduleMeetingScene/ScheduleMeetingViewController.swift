import SwiftUI
import Combine

final class ScheduleMeetingViewController: UIViewController {
    lazy var createBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.Meetings.ScheduleMeeting.create, style: .plain, target: self, action: #selector(createButtonItemTapped)
    )
    lazy var cancelBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.Meetings.ScheduleMeeting.cancel, style: .plain, target: self, action: #selector(cancelButtonItemTapped)
    )
    
    private(set) var viewModel: ScheduleMeetingViewModel
    
    private var subscriptions = Set<AnyCancellable>()

    lazy var hostingView = UIHostingController(rootView: ScheduleMeetingView(viewModel: viewModel))

    init(viewModel: ScheduleMeetingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubview()
        initSubscriptions()
        navigationItem.title = Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting
        navigationItem.rightBarButtonItem = createBarButtonItem
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        isModalInPresentation = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        createBarButtonItem.setTitleTextAttributes([.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)], for: .normal)
        cancelBarButtonItem.setTitleTextAttributes([.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)], for: .normal)
    }
    
    @objc func createButtonItemTapped() {
        viewModel.createDidTap()
    }
    
    @objc func cancelButtonItemTapped() {
        viewModel.cancelDidTap()
    }
    
    private func initSubscriptions() {
        subscriptions = [
            viewModel.$createButtonEnabled.sink(receiveValue: { [weak self] createButtonEnabled in
                self?.createBarButtonItem.isEnabled = createButtonEnabled
            })
        ]
    }
    
    private func configureSubview() {
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostingView.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingView.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingView.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
}
