import MEGADomain
import SwiftUI

public final class DeviceListViewModel: ObservableObject {
    private let router: any DeviceListRouting
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let backupStatuses: [BackupStatus]
    private var sortedBackupStatuses: [BackupStatusEntity: BackupStatus] {
        Dictionary(uniqueKeysWithValues: backupStatuses.map { ($0.status, $0) })
    }
    
    var isFilteredDevicesEmpty: Bool {
        filteredDevices.isEmpty
    }
    
    var isFiltered: Bool {
        isSearchActive && searchText.isNotEmpty
    }
    
    @Published private(set) var currentDevice: DeviceCenterItemViewModel?
    @Published private(set) var otherDevices: [DeviceCenterItemViewModel] = []
    @Published private(set) var filteredDevices: [DeviceCenterItemViewModel] = []
    @Published private(set) var deviceListAssets: DeviceListAssets
    @Published private(set) var emptyStateAssets: EmptyStateAssets
    @Published private(set) var searchAssets: SearchAssets
    @Published var isSearchActive: Bool
    @Published var searchText: String {
        didSet {
            filterDevices()
        }
    }
    
    init(
        router: any DeviceListRouting,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceListAssets: DeviceListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        backupStatuses: [BackupStatus]
    ) {
        self.router = router
        self.deviceCenterUseCase = deviceCenterUseCase
        self.deviceListAssets = deviceListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
        self.isSearchActive = false
        self.searchText = ""
        
        loadUserDevices()
    }
    
    func fetchUserDevices() async -> [DeviceEntity] {
        await deviceCenterUseCase.fetchUserDevices()
    }
    
    @MainActor
    func arrangeDevices(_ devices: [DeviceEntity]) {
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
        
        resetFilteredDevices()
    }
    
    private func loadUserDevices() {
        Task {
            let userDevices = await fetchUserDevices()
            await arrangeDevices(userDevices)
        }
    }
    
    private func resetFilteredDevices() {
        if let currentDevice {
            filteredDevices = [currentDevice] + otherDevices
        }
    }
    
    private func filterDevices() {
        if searchText.isNotEmpty {
            isSearchActive = true
            resetFilteredDevices()
            filteredDevices = filteredDevices.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            isSearchActive = false
            resetFilteredDevices()
        }
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
