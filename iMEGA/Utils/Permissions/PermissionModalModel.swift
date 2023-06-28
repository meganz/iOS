// The enum below used to present permission (audio recording , notifications etc)
// dialogs in a testable and configurable manner
// Models contain all data needed to present either UIAlertControlle or CustomModalAlertViewController
// which enables the PermssionAlertRouter to not be tied to any UIKit nor use any implicit singleton access
enum PermissionsModalModel {
    case alert(AlertModel)
    case custom(CustomModalModel)
}

struct AlertModel {
    var title: String
    var message: String
    var actions: [AlertAction]
    
    struct AlertAction {
        var title: String
        var style: UIAlertAction.Style
        var handler: () -> Void
    }
}

struct CustomModalModel {
    let image: UIImage
    let viewTitle: String
    let details: String
    let firstButtonTitle: String
    let dismissButtonTitle: String?
    let firstCompletion: (Dismisser) -> Void
}

struct Dismisser {
    var closure: () -> Void
    func callAsFunction() {
        closure()
    }
}

extension PermissionsModalModel {
    var viewController: UIViewController {
        switch self {
        case .alert(let model):
                return UIAlertController(model: model)
        case .custom(let model):
                let vc = CustomModalAlertViewController()
                vc.configure(with: model)
                return vc
        }
    }
}
