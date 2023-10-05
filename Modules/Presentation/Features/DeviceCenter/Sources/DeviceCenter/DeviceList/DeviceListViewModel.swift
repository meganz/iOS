import Combine
import MEGADomain
import MEGARepo
import MEGASwift
import SwiftUI

public final class DeviceListViewModel: ObservableObject {
    private let router: any DeviceListRouting
    private let deviceCenterBridge: DeviceCenterBridge
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let backupStatuses: [BackupStatus]
    private let deviceCenterActions: [DeviceCenterAction]
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let currentDeviceUUID: String
    private var cancellable: Set<AnyCancellable> = []
    private var searchTextPublisher = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?
    private var currentDeviceId: String?
    private let deviceIconNames: [BackupDeviceTypeEntity: String]
    private var sortedBackupStatuses: [BackupStatusEntity: BackupStatus] {
        Dictionary(uniqueKeysWithValues: backupStatuses.map { ($0.status, $0) })
    }
    private var sortedAvailableActions: [DeviceCenterActionType: [DeviceCenterAction]] {
        Dictionary(grouping: deviceCenterActions, by: \.type)
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
    @Published private(set) var refreshDevicesPublisher: PassthroughSubject<Void, Never>
    @Published var isSearchActive: Bool
    @Published var searchText: String = ""
    @Published var isLoadingPlaceholderVisible = false
    
    init(
        devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>,
        refreshDevicesPublisher: PassthroughSubject<Void, Never>,
        updateInterval: UInt64,
        router: any DeviceListRouting,
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceListAssets: DeviceListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        backupStatuses: [BackupStatus],
        deviceCenterActions: [DeviceCenterAction],
        deviceIconNames: [BackupDeviceTypeEntity: String]
    ) {
        self.devicesUpdatePublisher = devicesUpdatePublisher
        self.refreshDevicesPublisher = refreshDevicesPublisher
        self.updateInterval = updateInterval
        self.router = router
        self.deviceCenterBridge = deviceCenterBridge
        self.deviceCenterUseCase = deviceCenterUseCase
        self.deviceListAssets = deviceListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
        self.deviceCenterActions = deviceCenterActions
        self.deviceIconNames = deviceIconNames
        self.isSearchActive = false
        self.searchText = ""
        self.currentDeviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        setupSearchCancellable()
        setupDevicesUpdateSubscription()
        loadUserDevices()
        showLoadingPlaceholder()
    }
    
    private func showLoadingPlaceholder() {
        Task {
            await updateLoadingPlaceholderVisibility(true)
        }
    }
    
    private func setupSearchCancellable() {
        searchCancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterDevices()
            }
    }
    
    private func loadUserDevices() {
        Task {
            let userDevices = await fetchUserDevices()
            await arrangeDevices(userDevices)
        }
    }
    
    private func allDevices() -> [DeviceCenterItemViewModel] {
        if let currentDevice {
            return [currentDevice] + otherDevices
        }
        
        return otherDevices
    }
    
    private func filterDevices() {
        if searchText.isNotEmpty {
            isSearchActive = true
            filteredDevices = allDevices().filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            isSearchActive = false
            filteredDevices = allDevices()
        }
    }
    
    private func loadDeviceViewModel(_ device: DeviceEntity) -> DeviceCenterItemViewModel? {
        guard let deviceAssets = loadAssets(for: device),
              let availableActions = actionsForDevice(device) else {
            return nil
        }
        
        return DeviceCenterItemViewModel(
            router: router,
            refreshDevicesPublisher: refreshDevicesPublisher,
            deviceCenterUseCase: deviceCenterUseCase,
            deviceCenterBridge: deviceCenterBridge,
            itemType: .device(device),
            assets: deviceAssets,
            availableActions: availableActions
        )
    }
    
    private func loadDefaultDevice() {
        let device = DeviceEntity(
            id: currentDeviceUUID,
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
        let userAgent = device.backups?.first?.userAgent
        return ItemAssets(
            iconName: deviceIconName(userAgent: userAgent, isMobile: device.isMobileDevice() || device.id == currentDeviceUUID),
            status: backupStatus,
            defaultName: deviceListAssets.deviceDefaultName
        )
    }
    
    func deviceIconName(userAgent: String?, isMobile: Bool) -> String {
        let defaultIcon = isMobile ? BackupDeviceTypeEntity.defaultMobile : BackupDeviceTypeEntity.defaultPc
        let defaultIconName = deviceIconNames[defaultIcon] ?? ""

        guard let userAgent = userAgent else { return defaultIconName }
        
        if let bestMatch = deviceIconNames
            .compactMap({ (key, value) -> (iconName: String, priority: Int)? in
                guard userAgent.lowercased().matches(regex: key.toRegexString()) else { return nil }
                return (iconName: value, priority: key.priority())
            }).max(by: { $0.priority < $1.priority }) {
                return bestMatch.iconName
            }

        return defaultIconName
    }
    
    private func setupDevicesUpdateSubscription() {
        devicesUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                guard let self = self else { return }
                Task {
                    await self.arrangeDevices(devices)
                }
            }
            .store(in: &cancellable)
    }
    
    func startAutoRefreshUserDevices() async throws {
        while true {
            if Task.isCancelled { return }
            try await Task.sleep(nanoseconds: updateInterval * 1_000_000_000)
            if Task.isCancelled { return }
            loadUserDevices()
        }
    }
    
    func fetchUserDevices() async -> [DeviceEntity] {
        await deviceCenterUseCase.fetchUserDevices()
    }
    
    @MainActor
    func arrangeDevices(_ devices: [DeviceEntity]) {
        currentDeviceId = deviceCenterUseCase.loadCurrentDeviceId()
        
        if let device = devices.first(where: { $0.id == currentDeviceId }),
           let currentDeviceVM = loadDeviceViewModel(device) {
            currentDevice = currentDeviceVM
        } else {
            loadDefaultDevice()
        }
        
        otherDevices = devices
            .filter { $0.id != currentDeviceId }
            .compactMap(loadDeviceViewModel)
        
        if isLoadingPlaceholderVisible {
            updateLoadingPlaceholderVisibility(false)
        }
    }
    
    func actionsForDevice(_ device: DeviceEntity) -> [DeviceCenterAction]? {
        var actionTypes = [DeviceCenterActionType]()

        if device.id == currentDeviceUUID || (device.id == currentDeviceId && device.isMobileDevice()) {
            actionTypes.append(.cameraUploads)
        }
        
        if device.id != currentDeviceUUID {
            actionTypes.append(.rename)
        }
        
        return actionTypes.compactMap { type in
            sortedAvailableActions[type]?.first
        }
    }
    
    @MainActor
    private func updateLoadingPlaceholderVisibility(_ shown: Bool) {
        isLoadingPlaceholderVisible = shown
    }
}
