import Combine
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGAPreference
import MEGARepo
import MEGASwift

@MainActor
final class ProgressIndicatorViewModel {
    private(set) var completedBytes: Int = 0
    private(set) var totalBytes: Int = 0
    private(set) var uploadTransfers: Int = 0
    private(set) var lastFailedTransfer: TransferEntity?
    
    private let transferCounterUseCase: any TransferCounterUseCaseProtocol
    private let transferInventoryUseCaseHelper = TransferInventoryUseCaseHelper()
    
    private var queuedUploadTransfers = [String]()
    private var isWidgetForbidden = false
    
    // MARK: - Tasks
    
    private var transferStartTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var transferUpdateTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var transferTemporaryErrorTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var transferFinishTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private var dismissTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    // MARK: - Published Properties
    
    @Published private(set) var progress: CGFloat = 0.0
    @Published private(set) var isHidden: Bool = true
    @Published private(set) var shouldShowUploadImage: Bool = false
    @Published private(set) var progressStrokeColor: CGColor = TokenColors.Support.success.cgColor
    @Published private(set) var shouldDismissWidget: Bool = false
    @Published private(set) var badgeState: TransferBadgeState = .none
    
    // Badge flags (private, used for badgeState calculation)
    @Published private var shouldShowPauseBadge: Bool = false
    @Published private var shouldShowCompletedBadge: Bool = false
    @Published private var shouldShowErrorBadge: Bool = false
    @Published private(set) var shouldShowOverquotaBadge: Bool = false
    
    @PreferenceWrapper(key: PreferenceKeyEntity.transfersPaused, defaultValue: false)
    private var transfersPaused: Bool
    
    // MARK: - Init and deinit
    
    init(transferCounterUseCase: some TransferCounterUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.transferCounterUseCase = transferCounterUseCase
        setupTransferMonitoring()
        bindBadgeStateUpdates()
        $transfersPaused.useCase = preferenceUseCase
    }
    
    deinit {
        transferStartTask?.cancel()
        transferUpdateTask?.cancel()
        transferTemporaryErrorTask?.cancel()
        transferFinishTask?.cancel()
        dismissTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func showWidgetIfNeeded() {
        isWidgetForbidden = false
        configureData()
    }
    
    func hideWidget(widgetForbidden: Bool = false) {
        isWidgetForbidden = widgetForbidden
        isHidden = true
        dismissTask?.cancel()
    }
    
    func configureData() {
        guard !isWidgetForbidden, totalBytes > 0 else {
            isHidden = true
            return
        }
        
        queuedUploadTransfers.removeAll()
        queuedUploadTransfers = transferInventoryUseCaseHelper.queuedUploadTransfers()
        
        if let lastFailedTransfer {
            updateStateBadge(for: lastFailedTransfer)
        } else {
            shouldShowErrorBadge = false
            shouldShowPauseBadge = false
        }
        
        if completedBytes == totalBytes && queuedUploadTransfers.isEmpty {
            updateForCompletedTransfers()
        } else {
            updateForActiveTransfers()
        }
    }
    
    func handleTransferPauseRequest(flag: Bool) {
        shouldShowPauseBadge = flag
    }
    
    /// Resets all transfer counters and state to zero.
    ///
    /// Call this when all bytes have been transferred, or when you want to clear accumulated transfer statistics.
    ///
    /// This ensures that progress and transfer counts do not carry over from previous state,
    /// so if the user starts new transfers, previous values are not taken into account and
    /// progress begins from zero. This maintains UI and state consistency and prevents showing
    /// stale or incorrect data to the user.
    func reset() {
        completedBytes = 0
        totalBytes = 0
        uploadTransfers = 0
        lastFailedTransfer = nil
    }
    
    // MARK: - Private Methods
    
    private func updateStateBadge(for transfer: TransferEntity) {
        guard let lastErrorExtended = transfer.lastErrorExtended else {
            return
        }
        
        switch lastErrorExtended {
        case .overquota:
            shouldShowOverquotaBadge = true
        case .generic:
            break // No badge for generic errors
        default:
            shouldShowErrorBadge = true
        }
    }
    
    private func updateForActiveTransfers() {
        isHidden = false
        shouldShowCompletedBadge = false
        shouldDismissWidget = false
        dismissTask?.cancel()
        progressStrokeColor = TokenColors.Support.success.cgColor
        
        let hasUploadTransfer = uploadTransfers > 0 || !queuedUploadTransfers.isEmpty
        shouldShowUploadImage = hasUploadTransfer
        
        if shouldShowOverquotaBadge {
            progressStrokeColor = hasUploadTransfer ? TokenColors.Support.success.cgColor : TokenColors.Support.warning.cgColor
        } else if transfersPaused {
            shouldShowPauseBadge = true
        }
    }
    
    private func updateForCompletedTransfers() {
        let completedTransfers = transferInventoryUseCaseHelper.completedTransfers(filteringUserTransfers: true)
        guard !completedTransfers.isEmpty else {
            isHidden = true
            return
        }
        
        isHidden = false
        
        if let failedTransfer = lastFailedTransfer {
            handleFailedTransfer(failedTransfer)
        } else {
            shouldShowCompletedBadge = true
            progressStrokeColor = TokenColors.Support.success.cgColor
            scheduleDismissAfterDelay()
        }
        
        reset()
    }
    
    private func handleFailedTransfer(_ transfer: TransferEntity) {
        guard let lastErrorExtended = transfer.lastErrorExtended else {
            shouldShowCompletedBadge = true
            progressStrokeColor = TokenColors.Support.success.cgColor
            scheduleDismissAfterDelay()
            return
        }
        
        if lastErrorExtended == .overquota {
            shouldShowOverquotaBadge = true
            progressStrokeColor = TokenColors.Support.warning.cgColor
        } else if lastErrorExtended != .generic {
            shouldShowErrorBadge = true
            progressStrokeColor = TokenColors.Support.error.cgColor
        }
    }
    
    private func setupTransferMonitoring() {
        transferStartTask = Task { [weak self, transferCounterUseCase] in
            for await transfer in transferCounterUseCase.transferStartUpdates {
                guard !Task.isCancelled else { break }
                self?.handleTransferStart(transfer)
            }
        }
        
        transferUpdateTask = Task { [weak self, transferCounterUseCase] in
            for await transfer in transferCounterUseCase.transferUpdates {
                guard !Task.isCancelled else { break }
                self?.handleTransferUpdate(transfer)
            }
        }
        
        transferTemporaryErrorTask = Task { [weak self, transferCounterUseCase] in
            for await transferResponse in transferCounterUseCase.transferTemporaryErrorUpdates {
                guard !Task.isCancelled else { break }
                self?.handleTransferTemporaryErrorUpdate(transferResponse)
            }
        }
        
        transferFinishTask = Task { [weak self, transferCounterUseCase] in
            for await transferResponse in transferCounterUseCase.transferFinishUpdates {
                guard !Task.isCancelled else { break }
                self?.handleTransferFinish(transferResponse.transferEntity)
            }
        }
    }
    
    private func handleTransferStart(_ transfer: TransferEntity) {
        if transfer.type == .download, shouldShowOverquotaBadge {
            shouldShowOverquotaBadge = false
            progressStrokeColor = TokenColors.Support.success.cgColor
        }
        if transfer.type == .upload {
            uploadTransfers += 1
        }
        
        totalBytes += transfer.totalBytes
        completedBytes += transfer.transferredBytes
        updateProgress()
        configureData()
    }
    
    private func handleTransferUpdate(_ transfer: TransferEntity) {
        completedBytes += transfer.deltaSize ?? 0
        updateProgress()
    }
    
    private func handleTransferTemporaryErrorUpdate(_ transferResponse: TransferResponseEntity) {
        shouldShowOverquotaBadge = transferResponse.error.type == .quotaExceeded || transferResponse.error.type == .notEnoughQuota
        progressStrokeColor = shouldShowOverquotaBadge ? TokenColors.Support.warning.cgColor : TokenColors.Support.success.cgColor
    }
    
    private func handleTransferFinish(_ transfer: TransferEntity) {
        if transfer.type == .upload,
           uploadTransfers > 0 {
            uploadTransfers -= 1
        }
        if transfer.state == .cancelled {
            cancelTransfer(transferredBytes: transfer.transferredBytes, totalBytes: transfer.totalBytes)
        } else if transfer.type == .download {
            completedBytes += transfer.deltaSize ?? 0
        }
        
        if transfer.state == .failed {
            lastFailedTransfer = transfer
        }
        updateProgress()
        configureData()
    }
    
    private func cancelTransfer(transferredBytes: Int, totalBytes: Int) {
        completedBytes = max(0, completedBytes - transferredBytes)
        self.totalBytes -= totalBytes
    }
    
    private func updateProgress() {
        guard totalBytes > 0 else {
            progress = 0.0
            return
        }
        let rawProgress = CGFloat(completedBytes) / CGFloat(totalBytes)
        progress = min(max(rawProgress, 0.0), 1.0)
    }
    
    private func bindBadgeStateUpdates() {
        Publishers.CombineLatest4(
            $shouldShowErrorBadge,
            $shouldShowOverquotaBadge,
            $shouldShowPauseBadge,
            $shouldShowCompletedBadge
        )
        .map { showError, showOverquota, showPause, showCompleted -> TransferBadgeState in
            var active: [TransferBadgeState] = []
            if showError { active.append(.error) }
            if showOverquota { active.append(.overquota) }
            if showPause { active.append(.paused) }
            if showCompleted { active.append(.completed) }
            return active.max(by: { $0.priority < $1.priority }) ?? .none
        }
        .removeDuplicates()
        .assign(to: &$badgeState)
    }
    
    private func scheduleDismissAfterDelay() {
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            
            guard !Task.isCancelled else { return }
            self?.shouldDismissWidget = true
        }
    }
}
