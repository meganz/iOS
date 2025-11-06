import Combine
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGASwiftUI

@MainActor
public final class FileVersioningViewModel: ObservableObject {
    private let fileVersionsUseCase: any FileVersionsUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    
    @Published private(set) var isFileVersioningEnabled: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var fileVersionCount: Int = 0
    @Published private(set) var fileVersionMessage: String = ""
    @Published var showDisableAlert: Bool = false
    @Published var showDeleteOlderVersionsAlert: Bool = false
    @Published var snackBar: SnackBar?
    
    private(set) var updateFileVersioningTask: Task<Void, Never>? { didSet { oldValue?.cancel() } }
    private(set) var deleteOlderVersionTask: Task<Void, Never>? { didSet { oldValue?.cancel() } }
    
    public init(
        fileVersionsUseCase: some FileVersionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.fileVersionsUseCase = fileVersionsUseCase
        self.accountUseCase = accountUseCase
    }
    
    deinit {
        updateFileVersioningTask?.cancel()
        deleteOlderVersionTask?.cancel()
    }
    
    // MARK: - File versioning data
    func setupFileVersioning() async {
        // Get file version count and size
        refreshFileVersions()
        
        // Get current file versioning status
        do {
            isFileVersioningEnabled = try await fileVersionsUseCase.isFileVersionsEnabled()
        } catch let error {
            guard case FileVersionErrorEntity.optionNeverSet = error else { return }
            isFileVersioningEnabled = true
        }
    }
    
    private func refreshFileVersions() {
        let fileVersionTotalSize = String.memoryStyleString(fromByteCount: fileVersionsUseCase.rootNodeFileVersionTotalSizeInBytes())
        
        fileVersionCount = Int(fileVersionsUseCase.rootNodeFileVersionCount())
        
        fileVersionMessage = Strings.Localizable.Settings.FileManagement.FileVersioning.EnabledState.fileVersions(fileVersionCount) + " " + Strings.Localizable.Settings.FileManagement.FileVersioning.EnabledState.totalSizeTaken(fileVersionCount)
            .replacingOccurrences(of: "[storageSpace]", with: fileVersionTotalSize)
    }
    
    // MARK: - File versioning toggle
    func toggleFileVersioning(isCurrentlyEnabled: Bool) {
        if isCurrentlyEnabled {
            showDisableAlert = true
        } else {
            updateFileVersioning(isEnabled: true)
        }
    }
    
    func updateFileVersioning(isEnabled: Bool) {
        updateFileVersioningTask = Task { [weak self] in
            guard let self else { return }
            
            guard let isEnabled = try? await fileVersionsUseCase.enableFileVersions(isEnabled) else { return }
            isFileVersioningEnabled = isEnabled
        }
    }
    
    // MARK: - Delete older versions
    func onTapDeleteAllOlderVersionsButton() {
        showDeleteOlderVersionsAlert = true
    }
    
    func deleteOlderVersions() {
        guard !isLoading else { return }
        
        isLoading = true
        deleteOlderVersionTask = Task { [weak self] in
            guard let self else { return }
            
            let isDeleted = try? await fileVersionsUseCase.deletePreviousFileVersions()
            guard isDeleted == true else {
                isLoading = false
                return
            }

            _ = try? await accountUseCase.refreshCurrentAccountDetails()
            showSnackBar(message: Strings.Localizable.Settings.FileManagement.FileVersioning.DeleteOlderVersions.snackBar)
            refreshFileVersions()
            isLoading = false
        }
    }
    
    // MARK: - Snackbar
    private func showSnackBar(message: String) {
        snackBar = .init(message: message)
    }
}
