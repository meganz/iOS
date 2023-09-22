import Combine
import MEGADomain
import MEGAPresentation
import MEGAUIKit
import SwiftUI

public protocol BackupListRouting: Routing {
    func updateTitle(_ title: String)
}

public final class BackupListViewRouter: NSObject, BackupListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let deviceCenterBridge: DeviceCenterBridge
    private let selectedDeviceId: String
    private let selectedDeviceName: String
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let backups: [BackupEntity]
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
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
        nodeUseCase: any NodeUseCaseProtocol,
        navigationController: UINavigationController?,
        deviceCenterBridge: DeviceCenterBridge,
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
        self.nodeUseCase = nodeUseCase
        self.navigationController = navigationController
        self.deviceCenterBridge = deviceCenterBridge
        self.backupListAssets = backupListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
        self.deviceCenterActions = deviceCenterActions
    }
    
    public func build() -> UIViewController {
        let backupListViewModel = BackupListViewModel(
            selectedDeviceId: selectedDeviceId,
            selectedDeviceName: selectedDeviceName,
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            router: self,
            deviceCenterBridge: deviceCenterBridge,
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
        updateTitle(selectedDeviceName)

        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    public func updateTitle(_ title: String) {
        baseViewController?.title = title
        baseViewController?.navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: title)
    }
}
