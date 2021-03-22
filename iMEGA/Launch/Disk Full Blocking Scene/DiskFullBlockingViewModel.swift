import Foundation

enum DiskFullBlockingAction: ActionType {
    case onViewLoaded
    case manage
}

protocol DiskFullBlockingViewRouting: Routing {
    func manageDiskSpace()
}

struct DiskFullBlockingViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, description: NSAttributedString, manageTitle: String)
    }
    
    var invokeCommand: ((Command) -> Void)?
    private var router: DiskFullBlockingViewRouting
    private let deviceModel: String
    
    init(router: DiskFullBlockingViewRouting, deviceModel: String) {
        self.router = router
        self.deviceModel = deviceModel
    }
    
    func dispatch(_ action: DiskFullBlockingAction) {
        switch action {
        case .onViewLoaded:
            let title = NSLocalizedString("The device does not have enough space for MEGA to run properly.", comment: "")
            invokeCommand?(.configView(title: title,
                                       description: buildDescriptionText(),
                                       manageTitle: NSLocalizedString("Manage", comment: "")))
        case .manage:
            router.manageDiskSpace()
        }
    }
    
    private func buildDescriptionText() -> NSAttributedString {
        let storagePath = String(format: NSLocalizedString("Settings > General > %@ Storage", comment: ""), deviceModel)
        let text = String(format: NSLocalizedString("Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@", comment: ""), storagePath)
        let attributedString =
            NSMutableAttributedString(string: text,
                                      attributes:
                                        [.font : UIFont.preferredFont(forTextStyle: .subheadline)])
        let range = NSString(string: text).range(of: storagePath)
        attributedString.addAttributes([.font : UIFont.preferredFont(forTextStyle: .subheadline).bold()],
                                       range: range)
        return attributedString.copy() as! NSAttributedString
    }
}
