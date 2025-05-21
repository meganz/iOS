import Combine
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

public extension Notification.Name {
    static let shouldChangeCameraUploadsBackupName = Notification.Name("shouldChangeCameraUploadsBackupName")
}

enum SortType: Int {
    case ascending = 0, descending, largest, smallest, newest, oldest, label, favourite
}

@MainActor
public final class BackupListViewModel: ObservableObject {
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let router: any BackupListRouting
    private let deviceCenterBridge: DeviceCenterBridge
    private let deviceCenterActions: [ContextAction]
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let updateInterval: UInt64
    private let notificationCenter: NotificationCenter
    private(set) var selectedDevice: SelectedDevice
    private let backupStatusProvider: any BackupStatusProviding
    private let folderIconProvider: any FolderIconProviding
    private var sortedAvailableActions: [ContextAction.Category: [ContextAction]]?
    
    private var backupsPreloaded = false
    private var searchCancellable: AnyCancellable?
    private var backupNameChangeObserver: Any?
    private var networkMonitorTask: Task<Void, Never>?
    private var shouldChangeCUBackupNameTask: Task<Void, Never>?
    
    private var sortTypeSelected: SortType = .ascending
    
    var isFilteredBackupsEmpty: Bool {
        filteredBackups.isEmpty
    }
    
    var displayedBackups: [DeviceCenterItemViewModel] {
        isSearchActive && searchText.isNotEmpty ? filteredBackups : backupModels
    }
    
    @Published private(set) var backupModels: [DeviceCenterItemViewModel] = []
    @Published private(set) var filteredBackups: [DeviceCenterItemViewModel] = []
    @Published var isSearchActive: Bool
    @Published var searchText: String = ""
    @Published var hasNetworkConnection: Bool = false
    @Published var showEmptyStateView: Bool = false
    
    @Published var sortIndexSelected: Int = 0 {
        didSet {
            onSortTypeChanged()
        }
    }
    
    init(
        selectedDevice: SelectedDevice,
        devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>,
        updateInterval: UInt64,
        deviceCenterUseCase: some DeviceCenterUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        router: some BackupListRouting,
        deviceCenterBridge: DeviceCenterBridge,
        notificationCenter: NotificationCenter,
        backupStatusProvider: some BackupStatusProviding,
        folderIconProvider: some FolderIconProviding,
        deviceCenterActions: [ContextAction]
    ) {
        self.selectedDevice = selectedDevice
        self.devicesUpdatePublisher = devicesUpdatePublisher
        self.updateInterval = updateInterval
        self.deviceCenterUseCase = deviceCenterUseCase
        self.nodeUseCase = nodeUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.router = router
        self.deviceCenterBridge = deviceCenterBridge
        self.notificationCenter = notificationCenter
        self.backupStatusProvider = backupStatusProvider
        self.folderIconProvider = folderIconProvider
        self.deviceCenterActions = deviceCenterActions
        self.isSearchActive = false
        self.searchText = ""
        
        buildActionCategoryMapping()
        setupSearchCancellable()
        addObservers()
        
        if selectedDevice.backups.isEmpty {
            showEmptyStateView = true
        } else {
            loadBackupsInitialStatus()
        }
    }
    
    deinit {
        networkMonitorTask?.cancel()
        shouldChangeCUBackupNameTask?.cancel()
    }
    
    private func buildActionCategoryMapping() {
        sortedAvailableActions = Dictionary(grouping: deviceCenterActions, by: \.type)
    }
    
    private func addObservers() {
        if selectedDevice.isCurrent && selectedDevice.isMobile {
            shouldChangeCUBackupNameTask = Task { [weak self, notificationCenter] in
                for await _ in notificationCenter.notifications(named: .shouldChangeCameraUploadsBackupName) {
                    await self?.handleShouldChangeCameraUploadsBackupName()
                }
            }
        }
    }
    
    private func handleShouldChangeCameraUploadsBackupName() async {
        if self.showEmptyStateView,
           let currentDeviceId = self.deviceCenterUseCase.loadCurrentDeviceId() {
            self.selectedDevice.id = currentDeviceId
        }
        await syncDevicesAndLoadBackups()
    }
    
    private func setupSearchCancellable() {
        searchCancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterBackups()
            }
    }
    
    private func loadBackupsInitialStatus() {
        loadBackupsModels()
        backupsPreloaded = true
    }
    
    private func resetBackups() {
        filteredBackups = backupModels
    }
    
    private func filterBackups() {
        if searchText.isNotEmpty {
            filteredBackups = backupModels.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            resetBackups()
        }
        handleSortAction(sortTypeSelected)
    }
    
    private func monitorNetworkChanges() {
        let connectionSequence = networkMonitorUseCase.connectionSequence
        networkMonitorTask?.cancel()
        networkMonitorTask = Task { [weak self] in
            for await isConnected in connectionSequence {
                self?.hasNetworkConnection = isConnected
            }
        }
    }
    
    func updateInternetConnectionStatus() {
        hasNetworkConnection = networkMonitorUseCase.isConnected()
        monitorNetworkChanges()
    }
    
    func updateDeviceStatusesAndNotify() async throws {
        while true {
            if Task.isCancelled { return }
            try await Task.sleep(nanoseconds: updateInterval * 1_000_000_000)
            if Task.isCancelled { return }
            await syncDevicesAndLoadBackups()
        }
    }
    
    func syncDevicesAndLoadBackups() async {
        let devices = await deviceCenterUseCase.fetchUserDevices()
        updateCurrentDevice(devices)
        devicesUpdatePublisher.send(devices)
    }
    
    func updateCurrentDevice(_ devices: [DeviceEntity]) {
        guard let currentDevice = devices.first(where: { $0.id == selectedDevice.id }) else {
            showEmptyStateView = true
            return
        }
        
        let currentDeviceBackups = currentDevice.backups ?? []
        showEmptyStateView = currentDeviceBackups.isEmpty
        selectedDevice.backups = currentDeviceBackups
        loadBackupsModels()
        
        selectedDevice.name = currentDevice.name
        router.updateTitle(currentDevice.name)
    }
    
    func loadBackupsModels() {
        backupModels = selectedDevice.backups
            .compactMap { backup in
                if let assets = loadAssets(for: backup) {
                    return DeviceCenterItemViewModel(
                        deviceCenterUseCase: deviceCenterUseCase,
                        nodeUseCase: nodeUseCase,
                        deviceCenterBridge: deviceCenterBridge,
                        itemType: .backup(backup),
                        sortedAvailableActions: sortedAvailableActions ?? [:],
                        isCUActionAvailable: selectedDevice.isCurrent && selectedDevice.isMobile,
                        assets: assets,
                        currentDeviceUUID: { UIDevice.current.identifierForVendor?.uuidString ?? "" }
                    )
                }
                return nil
            }
        handleSortAction(sortTypeSelected)
    }
    
    func loadAssets(for backup: BackupEntity) -> ItemAssets? {
        guard let displayStatus = backup.toDisplayStatus(),
              let statusAssets = backupStatusProvider.backupDisplayAssets(for: displayStatus),
              let backupIcon = folderIconProvider.iconName(for: backup.type) else {
            return nil
        }
        
        return ItemAssets(
            iconName: backupIcon,
            statusAssets: statusAssets
        )
    }
    
    func actionTypesForDevice() -> [ContextAction.Category] {
        if selectedDevice.isNewDeviceWithoutCU {
            return [.cameraUploads]
        } else if selectedDevice.isCurrent && selectedDevice.isMobile {
            return [.rename, .info, .cameraUploads, .sort]
        }
        return [.rename, .info, .sort]
    }
    
    func availableActionsForCurrentDevice() -> [ContextAction] {
        actionTypesForDevice()
            .sortedMapping(sortedActions: sortedAvailableActions ?? [:])
    }
    
    func showCameraUploadsSettingsFlow() {
        Task {
            await executeDeviceAction(type: .cameraUploads)
        }
    }
    
    private func handleSortAction(_ type: SortType) {
        if isSearchActive && searchText.isNotEmpty {
            filteredBackups = filteredBackups.sorted(by: type)
        } else {
            backupModels = backupModels.sorted(by: type)
        }
    }
    
    func executeDeviceAction(type: ContextAction.Category) async {
        switch type {
        case .cameraUploads:
            deviceCenterBridge.cameraUploadActionTapped { [weak self] in
                Task {
                    if let currentDeviceId = self?.deviceCenterUseCase.loadCurrentDeviceId() {
                        self?.selectedDevice.id = currentDeviceId
                    }
                    await self?.syncDevicesAndLoadBackups()
                }
            }
        case .rename:
            let renameEntity = await makeRenameEntity()
            deviceCenterBridge.renameActionTapped(renameEntity)
        case .info:
            let infoModel = await makeDeviceInfoModel()
            deviceCenterBridge.infoActionTapped(infoModel)
        default: break
        }
    }
    
    private func makeRenameEntity() async -> RenameActionEntity {
        let deviceNames = await deviceCenterUseCase.fetchDeviceNames()
        
        return RenameActionEntity(
            oldName: selectedDevice.name,
            otherNamesInContext: deviceNames,
            actionType: .device(deviceId: selectedDevice.id, maxCharacters: 32),
            alertTitles: [
                .invalidCharacters: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay),
                .duplicatedName: Strings.Localizable.Device.Center.Rename.Device.Duplicated.name,
                .nameTooLong: Strings.Localizable.Device.Center.Rename.Device.Invalid.Long.name,
                .none: Strings.Localizable.rename
            ],
            alertMessage: [
                .duplicatedName: Strings.Localizable.Device.Center.Rename.Device.Different.name,
                .none: Strings.Localizable.renameNodeMessage
            ],
            alertPlaceholder: Strings.Localizable.Device.Center.Rename.Device.title
        ) {
            Task { [weak self] in
                await self?.syncDevicesAndLoadBackups()
            }
        }
    }
    
    private func makeDeviceInfoModel() async -> ResourceInfoModel {
        guard selectedDevice.backups.isNotEmpty else {
            return ResourceInfoModel(
                icon: MEGAAssets.Image.image(named: selectedDevice.icon),
                name: selectedDevice.name,
                counter: ResourceCounter.emptyCounter
            )
        }
        
        let folderInfo = await FolderInfoFactory(nodeUseCase: nodeUseCase).info(from: selectedDevice.backups)
        
        return ResourceInfoModel(
            icon: MEGAAssets.Image.image(named: selectedDevice.icon),
            name: selectedDevice.name,
            counter: ResourceCounter(
                files: folderInfo.files,
                folders: folderInfo.folders
            ),
            totalSize: folderInfo.totalSize
        )
    }
    
    private func onSortTypeChanged() {
        guard let sortType = SortType(rawValue: sortIndexSelected) else { return }
        sortTypeSelected = sortType
        handleSortAction(sortTypeSelected)
    }
}
