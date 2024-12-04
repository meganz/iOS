import Foundation
import MEGADomain
import MEGAUIComponent

@MainActor
final class RubbishBinSettingViewModel: ObservableObject {
    private let accountUseCase: any AccountUseCaseProtocol
    private let rubbishBinSettingsUseCase: any RubbishBinSettingsUseCaseProtocol
    private var onRubbishBinSettingsRequestFinishUpdatesTask: Task<Void, any Error>?
    
    @Published private(set) var isProAccount: Bool = false
    @Published private(set) var rubbishBinAutopurgePeriod: Int64 = 0
    @Published private(set) var isLoading = false
    @Published private(set) var selectedAutoPurgePeriod: AutoPurgePeriod = .sevenDays
    @Published private(set) var autoPurgePeriods = [AutoPurgePeriod]()
    
    @Published var isBottomSheetPresented = false
    
    // MARK: - Life Cycle
    
    init(accountUseCase: some AccountUseCaseProtocol, rubbishBinSettingsUseCase: some RubbishBinSettingsUseCaseProtocol) {
        self.accountUseCase = accountUseCase
        self.rubbishBinSettingsUseCase = rubbishBinSettingsUseCase
        
        isProAccount = accountUseCase.isProAccount
        autoPurgePeriods = AutoPurgePeriod.options(forProUser: isProAccount)
    }
    
    // MARK: Monitor Settings Change
    
    func startRubbishBinSettingsUpdatesMonitoring() async {
        onRubbishBinSettingsRequestFinishUpdatesTask?.cancel()
        onRubbishBinSettingsRequestFinishUpdatesTask = Task { [weak self, rubbishBinSettingsUseCase] in
            for await resultRequest in rubbishBinSettingsUseCase.onRubbishBinSettinghsRequestFinish {
                guard let self else { return }
                try Task.checkCancellation()
                
                handleRequestResult(resultRequest)
            }
        }
    }
    
    // MARK: Actions
    
    func onTapUpgradeButtton() {
        UpgradeAccountRouter().presentUpgradeTVC()
    }
    
    func onTapAutoPurgeCell() {
        isBottomSheetPresented = true
    }
    
    func onTapAutoPurgeRow(with period: AutoPurgePeriod) {
        selectedAutoPurgePeriod = period
        isBottomSheetPresented = false
    }
    
    func onTapEmptyBinButton() {
        guard MEGAReachabilityManager.isReachableHUDIfNot(), !isLoading else { return }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
        }
    }
    
    // MARK: - Private
    
    private func handleRequestResult(_ result: Result<RubbishBinSettingsEntity, any Error>) {
        if case .success(let result) = result {
            self.rubbishBinAutopurgePeriod = result.rubbishBinAutopurgePeriod
        }
    }
}
