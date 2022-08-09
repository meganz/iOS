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
            let storagePath = Strings.Localizable.settingsGeneralStorage(deviceModel)
            let description = Strings.Localizable.FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery.youCanManageYourStorageIn(storagePath)
            let blockingModel = DiskFullBlockingModel(title: Strings.Localizable.theDeviceDoesNotHaveEnoughSpaceForMEGAToRunProperly,
                                                      description: description,
                                                      highlightedText: storagePath,
                                                      manageDiskSpaceTitle: Strings.Localizable.manage,
                                                      headerImageName: Asset.Images.WarningStorageAlmostFull.blockingDiskFull.name)
            invokeCommand?(.configView(blockingModel))
        case .manage:
            router.manageDiskSpace()
        }
    }
}
