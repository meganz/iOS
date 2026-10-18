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
        observeDiscardAlert()
        isModalInPresentation = true
        
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
    
    /// Presented from UIKit so the sheet can be anchored to the Cancel button. Since iOS 26 an action sheet
    /// is shown as a popover pointing at its source, and a SwiftUI `.actionSheet` can only use the whole
    /// hosted view as the source, which squeezes the popover into the navigation bar.
    private func observeDiscardAlert() {
        viewModel.$showDiscardAlert
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self, presentedViewController == nil else { return }
                presentDiscardAlert()
            }
            .store(in: &subscriptions)
    }
    
    private func presentDiscardAlert() {
        let alertController = UIAlertController(
            title: Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.title,
            message: nil,
            preferredStyle: .actionSheet
        )
        let discardAction = UIAlertAction(
            title: Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.confirm,
            style: .destructive
        ) { [weak self] _ in
            Task {
                await self?.viewModel.discardChangesTap()
            }
        }
        discardAction.titleTextColor = TokenColors.Text.error
        alertController.addAction(discardAction)
        alertController.addAction(
            UIAlertAction(title: Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.cancel, style: .cancel) { [weak self] _ in
                self?.viewModel.keepEditingTap()
            }
        )
        alertController.popoverPresentationController?.sourceItem = cancelBarButtonItem
        present(alertController, animated: true)
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
