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
    private let selectedDevice: SelectedDevice
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let notificationCenter: NotificationCenter
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let deviceCenterActions: [ContextAction]
    private let backupStatusProvider: any BackupStatusProviding
    private let folderIconProvider: any FolderIconProviding
    
    public init(
        selectedDevice: SelectedDevice,
        devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>,
        updateInterval: UInt64,
        notificationCenter: NotificationCenter,
        deviceCenterUseCase: some DeviceCenterUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        navigationController: UINavigationController?,
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterActions: [ContextAction],
        backupStatusProvider: some BackupStatusProviding = BackupStatusProvider(),
        folderIconProvider: some FolderIconProviding = FolderIconProvider()
    ) {
        self.selectedDevice = selectedDevice
        self.devicesUpdatePublisher = devicesUpdatePublisher
        self.updateInterval = updateInterval
        self.notificationCenter = notificationCenter
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.navigationController = navigationController
        self.deviceCenterBridge = deviceCenterBridge
        self.deviceCenterActions = deviceCenterActions
        self.backupStatusProvider = backupStatusProvider
        self.folderIconProvider = folderIconProvider
    }
    
    public func build() -> UIViewController {
        let backupListViewModel = BackupListViewModel(
            selectedDevice: selectedDevice,
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            router: self,
            deviceCenterBridge: deviceCenterBridge,
            notificationCenter: notificationCenter,
            backupStatusProvider: backupStatusProvider,
            folderIconProvider: folderIconProvider,
            deviceCenterActions: deviceCenterActions
        )
        let backupListView = BackupListView(viewModel: backupListViewModel)
        let hostingController = UIHostingController(rootView: backupListView)
        baseViewController = hostingController
        updateTitle(selectedDevice.name)
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
