

@objc final class MeetingAlreadyExistsAlert: NSObject {
    @objc static func show(presenter: UIViewController) {
        let message = Strings.Localizable.Meetings.New.anotherAlreadyExistsError
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel))
        presenter.present(alertController, animated: true)
    }
    
    static func show(presenter: UIViewController, endAndJoinAlertHandler: (() -> Void)?) {
        let message = Strings.Localizable.Meetings.New.anotherAlreadyExistsError
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))

        if let handler = endAndJoinAlertHandler {
            let endAndJoinAlertAction = UIAlertAction(title: Strings.Localizable.Meetings.New.AnotherAlreadyExistsError.endAndJoin, style: .default) { _ in
                handler()
            }
            
            alertController.addAction(endAndJoinAlertAction)
        }
        
        presenter.present(alertController, animated: true)
    }
}
