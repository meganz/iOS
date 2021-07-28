import UIKit

final class EnterMeetingLinkViewHelper: NSObject {

    private let viewModel: EnterMeetingLinkViewModel
    private var link: String?
    private lazy var joinButton = UIAlertAction(title: NSLocalizedString("join", comment: ""), style: .default) { [weak self] (action) in
        guard let self = self, let link = self.link else { return }
        self.viewModel.dispatch(.didTapJoinButton(link))
    }
    
    init(viewModel: EnterMeetingLinkViewModel) {
        self.viewModel = viewModel
        super.init()
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
    }

    // MARK: - Dispatch action
    func executeCommand(_ command: EnterMeetingLinkViewModel.Command) {
        switch command {
        case .showEnterMeetingLink(let presenter):
            showEnterMeetingLink(presenter: presenter)
        case .linkError(let presenter):
            showLinkError(presenter: presenter)
        }
    }
    
    private func showEnterMeetingLink(presenter: UIViewController) {
        let alertViewController = UIAlertController(
            title: NSLocalizedString("meetings.enterMeetingLink.title", comment: ""),
            message: nil,
            preferredStyle: .alert)
        
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        joinButton.isEnabled = false
        alertViewController.addAction(joinButton)
        
        alertViewController.addTextField { [weak self] textfield in
            guard let self = self else { return }
            textfield.addTarget(self, action: #selector(self.textFieldTextChanged(_:)), for: .editingChanged)
            textfield.delegate = self
        }
        
        presenter.present(alertViewController, animated: true)
    }
    
    @objc private func textFieldTextChanged(_ textField: UITextField) {
        link = textField.text
        guard let link = link, !link.isEmpty else {
            joinButton.isEnabled = false
            return
        }
        joinButton.isEnabled = true
    }
    
    private func showLinkError(presenter: UIViewController) {
        let title = NSLocalizedString("meetings.joinMeeting.header", comment: "")
        let message = NSLocalizedString("meetings.joinMeeting.description", comment: "")
        let cancelButtonText = NSLocalizedString("ok", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelButtonText, style: .cancel))
        presenter.present(alert, animated: true)
    }
}

extension EnterMeetingLinkViewHelper: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        OperationQueue.main.addOperation {
            textField.select(nil)
            let menuController = UIMenuController.shared
            menuController.setMenuVisible(true, animated: true)
        }
    }
}
