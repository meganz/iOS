import MEGAL10n
import UIKit

final class EnterMeetingLinkControllerWrapper: NSObject {

    private let viewModel: EnterMeetingLinkViewModel
    private var link: String?
    private lazy var joinButton = UIAlertAction(title: Strings.Localizable.join, style: .default) { _ in
        guard let link = self.link else { return }
        Task { @MainActor in
            self.viewModel.dispatch(.didTapJoinButton(link))
        }
    }
    
    init(viewModel: EnterMeetingLinkViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    class func createViewController(withViewModel viewModel: EnterMeetingLinkViewModel) -> UIViewController {
        let wrapper = EnterMeetingLinkControllerWrapper(viewModel: viewModel)
        return wrapper.createAlertController()
    }
    
    private func createAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: Strings.Localizable.Meetings.EnterMeetingLink.title,
            message: nil,
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        joinButton.isEnabled = false
        alertController.addAction(joinButton)
        
        alertController.addTextField { textfield in
            textfield.addTarget(self, action: #selector(self.textFieldTextChanged(_:)), for: .editingChanged)
            textfield.delegate = self
        }
        
        return alertController
    }
    
    @objc private func textFieldTextChanged(_ textField: UITextField) {
        link = textField.text
        guard let link = link, !link.isEmpty else {
            joinButton.isEnabled = false
            return
        }
        joinButton.isEnabled = true
    }
}

extension EnterMeetingLinkControllerWrapper: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        OperationQueue.main.addOperation {
            if #available(iOS 16.0, *) {
                let interaction = UIEditMenuInteraction(delegate: nil)
                textField.addInteraction(interaction)
                let configuration = UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero)
                interaction.presentEditMenu(with: configuration)
            } else {
                textField.select(nil)
                let menuController = UIMenuController.shared
                menuController.showMenu(from: textField, rect: textField.bounds)
            }
        }
    }
}
