import Combine
import MEGADomain
import MEGAPresentation
import SwiftUI

public protocol BackupListRouting: Routing {
}

public final class BackupListViewRouter: NSObject, BackupListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let selectedDeviceId: String
    private let selectedDeviceName: String
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let backups: [BackupEntity]
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let backupListAssets: BackupListAssets
    private let emptyStateAssets: EmptyStateAssets
    private let searchAssets: SearchAssets
    private let backupStatuses: [BackupStatus]
    private let deviceCenterActions: [DeviceCenterAction]
    
    public init(
        selectedDeviceId: String,
        selectedDeviceName: String,
        devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>,
        updateInterval: UInt64,
        backups: [BackupEntity],
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        navigationController: UINavigationController?,
        backupListAssets: BackupListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        backupStatuses: [BackupStatus],
        deviceCenterActions: [DeviceCenterAction]
    ) {
        self.selectedDeviceId = selectedDeviceId
        self.selectedDeviceName = selectedDeviceName
        self.devicesUpdatePublisher = devicesUpdatePublisher
        self.updateInterval = updateInterval
        self.backups = backups
        self.deviceCenterUseCase = deviceCenterUseCase
        self.navigationController = navigationController
        self.backupListAssets = backupListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
        self.deviceCenterActions = deviceCenterActions
    }
    
    public func build() -> UIViewController {
        let backupListViewModel = BackupListViewModel(
            selectedDeviceId: selectedDeviceId,
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            deviceCenterUseCase: deviceCenterUseCase,
            router: self,
            backups: backups,
            backupListAssets: backupListAssets,
            emptyStateAssets: emptyStateAssets,
            searchAssets: searchAssets,
            backupStatuses: backupStatuses,
            deviceCenterActions: deviceCenterActions
        )
        let backupListView = BackupListView(viewModel: backupListViewModel)
        let hostingController = UIHostingController(rootView: backupListView)
        baseViewController = hostingController
        baseViewController?.title = selectedDeviceName

        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
