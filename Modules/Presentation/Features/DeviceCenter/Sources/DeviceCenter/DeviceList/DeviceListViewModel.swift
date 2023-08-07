import MEGADomain
import SwiftUI

public final class DeviceListViewModel: ObservableObject {
    private let router: any DeviceListRouting
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let backupStatuses: [BackupStatus]
    private var sortedBackupStatuses: [BackupStatusEntity: BackupStatus] {
        Dictionary(uniqueKeysWithValues: backupStatuses.map { ($0.status, $0) })
    }
    
    @Published var currentDevice: DeviceCenterItemViewModel?
    @Published var otherDevices: [DeviceCenterItemViewModel] = []
    @Published var deviceListAssets: DeviceListAssets
    
    init(
        router: any DeviceListRouting,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceListAssets: DeviceListAssets,
        backupStatuses: [BackupStatus]
    ) {
        self.router = router
        self.deviceCenterUseCase = deviceCenterUseCase
        self.deviceListAssets = deviceListAssets
        self.backupStatuses = backupStatuses
        
        fetchUserDevices()
    }
    
    private func fetchUserDevices() {
        Task {
            let userDevices = await deviceCenterUseCase.fetchUserDevices()
            await arrangeDevices(userDevices)
        }
    }
    
    @MainActor
    private func arrangeDevices(_ devices: [DeviceEntity]) {
        let currentDeviceId = deviceCenterUseCase.loadCurrentDeviceId()
        
        if let device = devices.first(where: { $0.id == currentDeviceId }),
           let currentDeviceVM = loadDeviceViewModel(device) {
            currentDevice = currentDeviceVM
        } else {
            loadDefaultDevice()
        }
        
        otherDevices = devices
            .filter { $0.id != currentDeviceId }
            .compactMap(loadDeviceViewModel)
    }
    
    private func loadDeviceViewModel(_ device: DeviceEntity) -> DeviceCenterItemViewModel? {
        guard let deviceAssets = loadAssets(for: device) else {
            return nil
        }
        
        return DeviceCenterItemViewModel(
            router: router,
            itemType: .device(device),
            assets: deviceAssets
        )
    }
    
    private func loadDefaultDevice() {
        let device = DeviceEntity(
            id: UIDevice.current.identifierForVendor?.uuidString ?? "",
            name: UIDevice.current.name,
            status: .noCameraUploads
        )
        
        if let deviceVM = loadDeviceViewModel(device) {
            currentDevice = deviceVM
        }
    }
    
    private func loadAssets(for device: DeviceEntity) -> ItemAssets? {
        guard let deviceStatus = device.status, let backupStatus = sortedBackupStatuses[deviceStatus] else {
            return nil
        }
        return ItemAssets(
            iconName: device.isMobileDevice() ? "mobile" : "pc",
            status: backupStatus,
            defaultName: deviceListAssets.deviceDefaultName
        )
    }
}
