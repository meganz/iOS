import MEGADomain
import SwiftUI

public final class DeviceListViewModel: ObservableObject {
    
    private let router: any DeviceListRouting
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    
    @Published var currentDevice: DeviceViewModel?
    @Published var otherDevices: [DeviceViewModel] = []
    @Published var deviceListAssets: DeviceListAssets
    
    init(
        router: any DeviceListRouting,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceListAssets: DeviceListAssets
    ) {
        self.router = router
        self.deviceCenterUseCase = deviceCenterUseCase
        self.deviceListAssets = deviceListAssets
        
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
        
        if let device = devices
            .first(where: { $0.id == currentDeviceId }) {
                if let assets = loadAssets(for: device) {
                        currentDevice = DeviceViewModel(device: device, assets: assets)
                }
        } else {
            loadDefaultDevice()
        }
        
        otherDevices = devices
            .compactMap { device in
                if device.id != currentDeviceId,
                   let assets = loadAssets(for: device) {
                    return DeviceViewModel(device: device, assets: assets)
                }
                return nil
            }
    }
    
    private func loadDefaultDevice() {
        let device = DeviceEntity(
            id: UIDevice.current.identifierForVendor?.uuidString ?? "",
            name: UIDevice.current.name,
            status: .noCameraUploads
        )
        
        if let status = deviceListAssets.sortedBackupStatuses[.noCameraUploads] {
            currentDevice = DeviceViewModel(device: device, assets: DeviceAssets(iconName: "mobile", status: status))
        }
    }
    
    private func loadAssets(for device: DeviceEntity) -> DeviceAssets? {
        guard let deviceStatus = device.status, let backupStatus = deviceListAssets.sortedBackupStatuses[deviceStatus] else {
            return nil
        }
        return DeviceAssets(iconName: device.isMobileDevice() ? "mobile" : "pc", status: backupStatus)
    }
}
