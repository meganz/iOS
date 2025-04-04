import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAUIKit
import SwiftUI

public protocol DeviceListRouting: Routing {
    func showDeviceBackups(_ device: DeviceEntity, deviceIcon: String, isCurrentDevice: Bool)
    func showCurrentDeviceEmptyState(_ deviceId: String, deviceName: String, deviceIcon: String)
}

public final class DeviceListViewRouter: NSObject, DeviceListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let deviceCenterBridge: DeviceCenterBridge
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let refreshDevicesPublisher: PassthroughSubject<Void, Never>
    private let updateInterval: UInt64
    private let deviceCenterActions: [ContextAction]
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let cameraUploadsUseCase: any CameraUploadsUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let backupStatusProvider: any BackupStatusProviding
    private let deviceIconProvider: any DeviceIconProviding

    public init(
        navigationController: UINavigationController?,
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterUseCase: some DeviceCenterUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        cameraUploadsUseCase: some CameraUploadsUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        notificationCenter: NotificationCenter,
        deviceCenterActions: [ContextAction],
        deviceIconProvider: some DeviceIconProviding = DeviceIconProvider(),
        backupStatusProvider: some BackupStatusProviding = BackupStatusProvider()
    ) {
        self.navigationController = navigationController
        self.deviceCenterBridge = deviceCenterBridge
        self.deviceCenterActions = deviceCenterActions
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.cameraUploadsUseCase = cameraUploadsUseCase
        self.notificationCenter = notificationCenter
        self.networkMonitorUseCase = networkMonitorUseCase
        self.devicesUpdatePublisher = PassthroughSubject<[DeviceEntity], Never>()
        self.refreshDevicesPublisher = PassthroughSubject<Void, Never>()
        self.updateInterval = 30
        self.backupStatusProvider = backupStatusProvider
        self.deviceIconProvider = deviceIconProvider
        
        super.init()
    }
    
    public func build() -> UIViewController {
        let deviceListViewModel = DeviceListViewModel(
            devicesUpdatePublisher: devicesUpdatePublisher,
            refreshDevicesPublisher: refreshDevicesPublisher,
            updateInterval: updateInterval,
            router: self,
            deviceCenterBridge: deviceCenterBridge,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            backupStatusProvider: backupStatusProvider,
            deviceCenterActions: deviceCenterActions,
            deviceIconProvider: deviceIconProvider,
            currentDeviceUUID: UIDevice.current.identifierForVendor?.uuidString ?? ""
        )
        
        let deviceListView = DeviceListView(viewModel: deviceListViewModel)
        let hostingController = UIHostingController(rootView: deviceListView)
        baseViewController = hostingController
        baseViewController?.title = Strings.Localizable.Device.Center.title
        baseViewController?.navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: Strings.Localizable.Device.Center.title)
        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    public func showDeviceBackups(
        _ device: DeviceEntity,
        deviceIcon: String,
        isCurrentDevice: Bool
    ) {
        guard let backups = device.backups else { return }
        
        BackupListViewRouter(
            selectedDevice: SelectedDevice(
                id: device.id,
                name: device.name.isEmpty ? UIDevice.current.modelName : device.name,
                icon: deviceIcon,
                isCurrent: isCurrentDevice,
                isNewDeviceWithoutCU: false,
                backups: backups
            ),
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            notificationCenter: notificationCenter,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            navigationController: navigationController,
            deviceCenterBridge: deviceCenterBridge,
            deviceCenterActions: deviceCenterActions,
            backupStatusProvider: backupStatusProvider
        ).start()
    }
    
    public func showCurrentDeviceEmptyState(
        _ deviceId: String,
        deviceName: String,
        deviceIcon: String
    ) {
        BackupListViewRouter(
            selectedDevice: SelectedDevice(
                id: deviceId,
                name: deviceName,
                icon: deviceIcon,
                isCurrent: true,
                isNewDeviceWithoutCU: true
            ),
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            notificationCenter: notificationCenter,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            navigationController: navigationController,
            deviceCenterBridge: deviceCenterBridge,
            deviceCenterActions: deviceCenterActions,
            backupStatusProvider: backupStatusProvider
        ).start()
    }
}
