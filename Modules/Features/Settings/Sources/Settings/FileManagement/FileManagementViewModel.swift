import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGASwiftUI

@MainActor
public final class FileManagementViewModel: ObservableObject {
    private let cacheUseCase: any CacheUseCaseProtocol
    private let offlineUseCase: any OfflineUseCaseProtocol
    private let mobileDataUseCase: any MobileDataUseCaseProtocol
    private let fileVersionsUseCase: any FileVersionsUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    
    private let removeOfflineFilesCompletion: () -> Void
    private let navigateToRubbishBinSettings: () -> Void
    private let navigateToFileVersioning: () -> Void
    
    @Published private(set) var isMobileDataEnabled: Bool = false
    @Published private(set) var formattedCacheSize: String = ""
    @Published private(set) var formattedOfflineFilesSize: String = ""
    @Published var showClearOfflineFilesAlert: Bool = false
    @Published var snackBar: SnackBar?
    
    private(set) var clearCacheTask: Task<Void, Never>? { didSet { oldValue?.cancel() } }
    private(set) var clearOfflineFilesTask: Task<Void, Never>? { didSet { oldValue?.cancel() } }
    
    public init(
        cacheUseCase: some CacheUseCaseProtocol,
        offlineUseCase: some OfflineUseCaseProtocol,
        mobileDataUseCase: some MobileDataUseCaseProtocol,
        fileVersionsUseCase: some FileVersionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        removeOfflineFilesCompletion: @escaping () -> Void,
        navigateToRubbishBinSettings: @escaping () -> Void,
        navigateToFileVersioning: @escaping () -> Void
    ) {
        self.cacheUseCase = cacheUseCase
        self.offlineUseCase = offlineUseCase
        self.mobileDataUseCase = mobileDataUseCase
        self.fileVersionsUseCase = fileVersionsUseCase
        self.accountUseCase = accountUseCase
        self.removeOfflineFilesCompletion = removeOfflineFilesCompletion
        self.navigateToRubbishBinSettings = navigateToRubbishBinSettings
        self.navigateToFileVersioning = navigateToFileVersioning
    }
    
    deinit {
        clearCacheTask?.cancel()
        clearOfflineFilesTask?.cancel()
    }
    
    func setupFileManagement() {
        updateMobileDataUsage()
        updateCacheSize()
        updateOfflineFilesSize()
    }
    
    // MARK: - Mobile Data
    func toggleMobileDataUsage(isCurrentlyEnabled: Bool) {
        mobileDataUseCase.updateMobileDataForPreviewingEnabled(!isCurrentlyEnabled)
        updateMobileDataUsage()
    }
    
    func updateMobileDataUsage() {
        isMobileDataEnabled = mobileDataUseCase.isMobileDataForPreviewingEnabled()
    }
    
    // MARK: - Cache
    func clearCache() async throws {
        try await cacheUseCase.cleanCache()
    }
    
    private func updateCacheSize() {
        do {
            let cacheSize = try cacheUseCase.cacheSize()
            formattedCacheSize = String.memoryStyleString(fromByteCount: Int64(cacheSize))
        } catch {
            formattedCacheSize = String.memoryStyleString(fromByteCount: Int64(0))
        }
    }
    
    // MARK: - Offline Files
    func clearOfflineFiles() {
        clearOfflineFilesTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try Task.checkCancellation()
                try await offlineUseCase.removeAllOfflineFiles()
                try Task.checkCancellation()
                removeOfflineFilesCompletion()
                showSnackBar(message: Strings.Localizable.Settings.FileManagement.ClearOfflineFiles.Done.message)
                updateOfflineFilesSize()
            } catch is CancellationError {
                MEGALogError("[FileManagement] Offline files clearing task was cancelled")
            } catch {
                MEGALogError("[FileManagement] error when clearing offline files: \(error)")
            }
        }
    }
    
    func updateOfflineFilesSize() {
        let offlineFilesSize = offlineUseCase.offlineSize()
        formattedOfflineFilesSize = String.memoryStyleString(fromByteCount: Int64(offlineFilesSize))
    }
    
    func hasOfflineFiles() -> Bool {
        offlineUseCase.offlineSize() != 0
    }
    
    // MARK: - Snackbar
    private func showSnackBar(message: String) {
        snackBar = .init(message: message)
    }
    
    // MARK: - Actions
    func onTapRubbishBinSettings() {
        navigateToRubbishBinSettings()
    }
    
    func onTapFileVersioning() {
        navigateToFileVersioning()
    }
    
    func onTapClearOfflineFiles() {
        if hasOfflineFiles() {
            showClearOfflineFilesAlert = true
        }
    }
    
    func onTapClearCache() {
        clearCacheTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try Task.checkCancellation()
                try await clearCache()
                try Task.checkCancellation()
                showSnackBar(message: Strings.Localizable.Settings.FileManagement.ClearCache.Done.message)
                updateCacheSize()
            } catch is CancellationError {
                MEGALogError("[FileManagement] Cache clearing task was cancelled")
            } catch {
                MEGALogError("[FileManagement] error when clearing cache: \(error)")
            }
        }
    }
}
