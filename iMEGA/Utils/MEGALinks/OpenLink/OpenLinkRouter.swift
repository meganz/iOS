import MEGAAppPresentation
import MEGAL10n

final class OpenLinkRouter: Routing {
    private weak var presenter: UIViewController?
    private let linkManager: any MEGALinkManagerProtocol.Type

    private static let supportedLinkTypes: Set<URLType> = [
        .fileLink,
        .folderLink,
        .collection,
        .contactLink,
        .publicChatLink
    ]

    init(
        presenter: UIViewController,
        linkManager: any MEGALinkManagerProtocol.Type = MEGALinkManager.self
    ) {
        self.presenter = presenter
        self.linkManager = linkManager
    }

    func start() {
        presenter?.present(build(), animated: true)
    }

    func build() -> UIViewController {
        let alertController = UIAlertController(
            title: Strings.Localizable.OpenLink.title,
            message: Strings.Localizable.OpenLink.inputMessage,
            preferredStyle: .alert
        )

        let openAction = UIAlertAction(title: Strings.Localizable.openButton, style: .default) { [weak self, weak alertController] _ in
            guard let self else { return }
            let linkText = alertController?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.processLink(linkText)
        }
        openAction.isEnabled = false

        alertController.addTextField { textField in
            textField.addAction(UIAction { [weak openAction] action in
                guard let textField = action.sender as? UITextField else { return }
                let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                openAction?.isEnabled = !text.isEmpty
            }, for: .editingChanged)
        }

        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(openAction)

        return alertController
    }

    private func processLink(_ linkText: String) {
        guard let url = URL(string: linkText),
              Self.supportedLinkTypes.contains((url as NSURL).mnz_type()) else {
            presenter?.showSnackBar(message: Strings.Localizable.OpenLink.invalidLinkMessage)
            return
        }

        linkManager.adapterLinkURL = url
        linkManager.processLinkURL(url)
    }
}
