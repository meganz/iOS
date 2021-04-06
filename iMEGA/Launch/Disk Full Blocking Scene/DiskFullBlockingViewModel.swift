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
        case configView(DiskFullBlockingModel)
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
            let storagePath = String(format: NSLocalizedString("Settings > General > %@ Storage", comment: ""), deviceModel)
            let description = String(format: NSLocalizedString("Free up some space by deleting apps you no longer use or large video files in your gallery. You can manage your storage in %@", comment: ""), storagePath)
            let blockingModel = DiskFullBlockingModel(title: NSLocalizedString("The device does not have enough space for MEGA to run properly.", comment: ""),
                                                      description: description,
                                                      highlightedText: storagePath,
                                                      manageDiskSpaceTitle: NSLocalizedString("Manage", comment: ""),
                                                      headerImageName: "blockingDiskFull")
            invokeCommand?(.configView(blockingModel))
        case .manage:
            router.manageDiskSpace()
        }
    }
}
