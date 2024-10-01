protocol SendToChatPresenting {
    func showSendToChat(presenter: UIViewController)
}

protocol SendToChatPresentingFactoryProtocol {
    associatedtype SendToChat: SendToChatPresenting
    func make(link: String) -> SendToChat
}

struct SendToChatPresentingFactory: SendToChatPresentingFactoryProtocol {
    func make(link: String) -> some SendToChatPresenting {
        SendToChatWrapper(link: link)
    }
}

/// This class wrapper is intended to reuse the SendToChat functionality from different places in the app.
/// It configures the interface style and listen for delegate events to dismiss the view controller when the user finishes the action.
final class SendToChatWrapper: NSObject, Sendable, SendToChatPresenting {
    private let link: String
    private let interfaceStyle: UIUserInterfaceStyle?
    
    init(
        link: String,
        interfaceStyle: UIUserInterfaceStyle? = nil
    ) {
        self.link = link
        self.interfaceStyle = interfaceStyle
    }
    
    func showSendToChat( presenter: UIViewController ) {
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.sendToChatActivityDelegate = self
        sendToViewController.sendMode = .text
        if let interfaceStyle {
            navigationController.overrideUserInterfaceStyle = interfaceStyle
        }
        
        presenter.present(navigationController, animated: true)
    }
}

extension SendToChatWrapper: SendToChatActivityDelegate {
    func send(
        _ viewController: SendToViewController!,
        didFinishActivity completed: Bool
    ) {
        viewController.dismiss(animated: true)
    }
    
    func textToSend() -> String {
        link
    }
}
