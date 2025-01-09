import MEGAL10n

final class SendToChatActivity: UIActivity, SendToChatActivityDelegate {
    
    private var text: String
    
    init(text: String) {
        self.text = text
    }
    
    override var activityTitle: String? {
        Strings.Localizable.General.sendToChat
    }
    
    override var activityImage: UIImage? {
        UIImage(named: "activity_sendToChat")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }
    
    override class var activityCategory: UIActivity.Category {
        .action
    }
    
    override var activityViewController: UIViewController? {
        guard let navigationController = UIStoryboard(
            name: "Chat",
            bundle: nil
        )
            .instantiateViewController(
                withIdentifier: "SendToNavigationControllerID"
            ) as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return nil
        }
        
        sendToViewController.sendToChatActivityDelegate = self
        sendToViewController.sendMode = .text
        
        return navigationController
    }
    
    // MARK: - SendToChatActivityDelegate
    func send(_ viewController: SendToViewController, didFinishActivity completed: Bool) {
        activityDidFinish(completed)
    }
    
    func textToSend() -> String {
        text
    }
}
