import Combine
import MEGADomain
import MEGARepo
import MEGASwift
import MEGAUI
import SwiftUI

@MainActor
public final class DeviceListViewModel: ObservableObject {
    private let router: any DeviceListRouting
    private let deviceCenterBridge: DeviceCenterBridge
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let deviceCenterActions: [ContextAction]
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let currentDeviceUUID: String
    private let backupStatusProvider: BackupStatusProviding
    private var cancellable: Set<AnyCancellable> = []
    private var searchTextPublisher = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?
    private var currentDeviceId: String?
    private let deviceIconProvider: any DeviceIconProviding
    /// Dictionary that allow us to organize the different backup statuses by type.
    private var sortedBackupStatuses: [BackupStatusEntity: BackupStatus]?
    /// Dictionary that allow us to organise the different actions available within Device Center by type.
    /// It helps to initialise the arrays of available actions for each element (devices, backups, sync, or camera uploads folders)
    /// in a simple way, using the `ContextAction.Category`.
    private var sortedAvailableActions: [ContextAction.Category: [ContextAction]]?
    
    private var networkMonitorTask: Task<Void, Never>?
    
    var isFilteredDevicesEmpty: Bool {
        filteredDevices.isEmpty
    }
    var isFiltered: Bool {
        searchText.isNotEmpty
    }
    
    @Published private(set) var currentDevice: DeviceCenterItemViewModel?
    @Published private(set) var otherDevices: [DeviceCenterItemViewModel] = []
    @Published private(set) var filteredDevices: [DeviceCenterItemViewModel] = []
    @Published private(set) var refreshDevicesPublisher: PassthroughSubject<Void, Never>
    @Published var isSearchActive: Bool
    @Published var searchText: String = ""
    @Published var isLoadingPlaceholderVisible = false
    @Published var hasNetworkConnection: Bool = false
    
    init(
        devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>,
        refreshDevicesPublisher: PassthroughSubject<Void, Never>,
        updateInterval: UInt64,
        router: some DeviceListRouting,
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterUseCase: some DeviceCenterUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        backupStatusProvider: some BackupStatusProviding,
        deviceCenterActions: [ContextAction],
        deviceIconProvider: some DeviceIconProviding,
        currentDeviceUUID: String
    ) {
        self.devicesUpdatePublisher = devicesUpdatePublisher
        self.refreshDevicesPublisher = refreshDevicesPublisher
        self.updateInterval = updateInterval
        self.router = router
        self.deviceCenterBridge = deviceCenterBridge
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.backupStatusProvider = backupStatusProvider
        self.deviceCenterActions = deviceCenterActions
        self.deviceIconProvider = deviceIconProvider
        self.isSearchActive = false
        self.searchText = ""
        self.currentDeviceUUID = currentDeviceUUID
        
        buildBackupStatusLookup()
        buildActionCategoryMapping()
        setupSearchCancellable()
        setupDevicesUpdateSubscription()
        loadUserDevices()
        showLoadingPlaceholder()
    }
    
    deinit {
        networkMonitorTask?.cancel()
    }
    
    private func buildBackupStatusLookup() {
        let statuses = backupStatusProvider.createBackupStatuses()
        sortedBackupStatuses = Dictionary(uniqueKeysWithValues: statuses.map { ($0.status, $0) })
    }
    
    private func buildActionCategoryMapping() {
        sortedAvailableActions = Dictionary(grouping: deviceCenterActions, by: \.type)
    }
    
    private func showLoadingPlaceholder() {
        updateLoadingPlaceholderVisibility(true)
    }
    
    private func hideLoadingPlaceholder() {
        if isLoadingPlaceholderVisible {
            updateLoadingPlaceholderVisibility(false)
        }
    }
    
    private func setupSearchCancellable() {
        searchCancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.filterDevices() }
    }
    
    private func loadUserDevices() {
        Task {
            let userDevices = await fetchUserDevices()
            arrangeDevices(userDevices)
        }
    }
    
    private func allDevices() -> [DeviceCenterItemViewModel] {
        if let currentDevice {
            return [currentDevice] + otherDevices
        }
        return otherDevices
    }
    
    private func filterDevices() {
        filteredDevices = searchText.isNotEmpty ?
            allDevices().filter { $0.name.lowercased().contains(searchText.lowercased()) } :
            allDevices()
    }
    
    private func loadDeviceViewModel(_ device: DeviceEntity) -> DeviceCenterItemViewModel? {
        guard let deviceAssets = loadAssets(for: device) else { return nil }
        
        let isCUActionAvailable = device.id == currentDeviceUUID || (device.id == currentDeviceId && device.isMobileDevice())
        return DeviceCenterItemViewModel(
            router: router,
            refreshDevicesPublisher: refreshDevicesPublisher,
            deviceCenterUseCase: deviceCenterUseCase,
            nodeUseCase: nodeUseCase,
            deviceCenterBridge: deviceCenterBridge,
            itemType: .device(device),
            sortedAvailableActions: sortedAvailableActions ?? [:],
            isCUActionAvailable: isCUActionAvailable,
            assets: deviceAssets,
            currentDeviceUUID: { UIDevice.current.identifierForVendor?.uuidString ?? "" }
        )
    }
    
    private func loadDefaultDevice() {
        let device = DeviceEntity(
            id: currentDeviceUUID,
            name: UIDevice.current.modelName,
            status: .noCameraUploads
        )
        if let deviceVM = loadDeviceViewModel(device) {
            currentDevice = deviceVM
        }
    }
    
    func loadAssets(for device: DeviceEntity) -> ItemAssets? {
        guard let deviceStatus = device.status,
              let backupStatus = sortedBackupStatuses?[deviceStatus] else { return nil }
        let userAgent = device.backups?.first?.userAgent
        return ItemAssets(
            iconName: deviceIconProvider.iconName(for: userAgent, isMobile: device.isMobileDevice() || device.id == currentDeviceUUID),
            status: backupStatus,
            defaultName: UIDevice.current.modelName
        )
    }
    
    @MainActor
    private func updateLoadingPlaceholderVisibility(_ shown: Bool) {
        isLoadingPlaceholderVisible = shown
    }
    
    @MainActor
    private func monitorNetworkChanges() {
        let connectionSequence = networkMonitorUseCase.connectionSequence
        networkMonitorTask?.cancel()
        networkMonitorTask = Task { [weak self] in
            for await isConnected in connectionSequence {
                self?.hasNetworkConnection = isConnected
            }
        }
    }
    
    @MainActor
    func updateInternetConnectionStatus() {
        hasNetworkConnection = networkMonitorUseCase.isConnected()
        monitorNetworkChanges()
    }
    
    private func setupDevicesUpdateSubscription() {
        devicesUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in self?.arrangeDevices(devices) }
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
        do {
            otherDevices = try devices
                .filter { $0.id != currentDeviceId }
                .compactMap(loadDeviceViewModel)
                .sorted { $0.name < $1.name }
        } catch {
            debugPrint("[Device Center] Error while arranging devices: \(error.localizedDescription)")
        }
        hideLoadingPlaceholder()
    }
}
