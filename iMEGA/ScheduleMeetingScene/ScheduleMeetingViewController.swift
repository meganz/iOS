import Combine
import MEGADesignToken
import MEGAL10n
import SwiftUI

final class ScheduleMeetingViewController: UIViewController {
    lazy var createBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.Meetings.ScheduleMeeting.create, style: .plain, target: self, action: #selector(submitButtonItemTapped)
    )
    lazy var updateBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.Meetings.ScheduleMeeting.update, style: .plain, target: self, action: #selector(submitButtonItemTapped)
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
        let title = viewModel.title
        navigationItem.title = title
        updateRightBarButton(
            viewModel.isNewMeeting ? createBarButtonItem : updateBarButtonItem,
            enablePublisher: viewModel.$isRightBarButtonEnabled
        )
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        setMenuCapableBackButtonWith(menuTitle: title)
        isModalInPresentation = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        createBarButtonItem.setTitleTextAttributes([.foregroundColor: TokenColors.Text.primary], for: .normal)
        cancelBarButtonItem.setTitleTextAttributes([.foregroundColor: TokenColors.Text.primary], for: .normal)
    }
    
    @objc func submitButtonItemTapped() {
        Task {
            await viewModel.submitButtonTapped()
        }
    }
    
    @objc func cancelButtonItemTapped() {
        Task {
            await viewModel.cancelDidTap()
        }
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
    
    private func updateRightBarButton(_ barButtonItem: UIBarButtonItem, enablePublisher: Published<Bool>.Publisher) {
        navigationItem.rightBarButtonItem = barButtonItem
        enablePublisher.sink { [weak self] isEnabled in
            guard let self,
                  let barButtonItem = navigationItem.rightBarButtonItem,
                  barButtonItem.isEnabled != isEnabled else {
                return
            }
            
            barButtonItem.isEnabled = isEnabled
        }.store(in: &subscriptions)
    }
}
