import Combine
import MEGADomain
import MEGAPresentation
import MEGAUIKit
import SwiftUI

public protocol DeviceListRouting: Routing {
    func showDeviceBackups(_ device: DeviceEntity)
}

public final class DeviceListViewRouter: NSObject, DeviceListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let deviceCenterAssets: DeviceCenterAssets
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    
    public init(
        navigationController: UINavigationController?,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceCenterAssets: DeviceCenterAssets
    ) {
        self.navigationController = navigationController
        self.deviceCenterAssets = deviceCenterAssets
        self.deviceCenterUseCase = deviceCenterUseCase
        
        devicesUpdatePublisher = PassthroughSubject<[DeviceEntity], Never>()
        updateInterval = 30
        
        super.init()
    }
    
    public func build() -> UIViewController {
        let deviceListViewModel = DeviceListViewModel(
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            router: self,
            deviceCenterUseCase: deviceCenterUseCase,
            deviceListAssets: deviceCenterAssets.deviceListAssets,
            emptyStateAssets: deviceCenterAssets.emptyStateAssets,
            searchAssets: deviceCenterAssets.searchAssets,
            backupStatuses: deviceCenterAssets.backupStatuses,
            deviceCenterActions: deviceCenterAssets.deviceCenterActions
        )
        let deviceListView = DeviceListView(viewModel: deviceListViewModel)
        let hostingController = UIHostingController(rootView: deviceListView)
        baseViewController = hostingController
        baseViewController?.title = deviceCenterAssets.deviceListAssets.title
        baseViewController?.navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: deviceCenterAssets.deviceListAssets.title)

        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    public func showDeviceBackups(_ device: DeviceEntity) {
        guard let backups = device.backups else { return }
        
        BackupListViewRouter(
            selectedDeviceId: device.id,
            selectedDeviceName: device.name.isEmpty ? deviceCenterAssets.deviceListAssets.deviceDefaultName : device.name,
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            backups: backups,
            deviceCenterUseCase: deviceCenterUseCase,
            navigationController: navigationController,
            backupListAssets: deviceCenterAssets.backupListAssets,
            emptyStateAssets: deviceCenterAssets.emptyStateAssets,
            searchAssets: deviceCenterAssets.searchAssets,
            backupStatuses: deviceCenterAssets.backupStatuses,
            deviceCenterActions: deviceCenterAssets.deviceCenterActions
        ).start()
    }
}
