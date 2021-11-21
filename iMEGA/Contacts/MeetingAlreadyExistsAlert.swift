

@objc final class MeetingAlreadyExistsAlert: NSObject {
    @objc static func show(presenter: UIViewController) {
        let message = NSLocalizedString("meetings.new.anotherAlreadyExistsError",
                                        comment: "Error text shown when trying to create or join a new meeting given that the user is already in another meeting")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel))
        presenter.present(alertController, animated: true)
    }
    
    static func show(presenter: UIViewController, endAndJoinAlertHandler: (() -> Void)?) {
        let message = NSLocalizedString("meetings.new.anotherAlreadyExistsError",
                                        comment: "Error text shown when trying to create or join a new meeting given that the user is already in another meeting")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))

        if let handler = endAndJoinAlertHandler {
            let endAndJoinAlertAction = UIAlertAction(title:  NSLocalizedString("meetings.new.anotherAlreadyExistsError.endAndJoin", comment: ""), style: .default) { _ in
                handler()
            }
            
            alertController.addAction(endAndJoinAlertAction)
        }
        
        presenter.present(alertController, animated: true)
    }
}
