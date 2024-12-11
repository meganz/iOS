import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent

@MainActor
final class RubbishBinSettingViewModel: ObservableObject {
    private let accountUseCase: any AccountUseCaseProtocol
    private let rubbishBinSettingsUseCase: any RubbishBinSettingsUseCaseProtocol
    private let upgradeAccountRouter: any UpgradeAccountRouting
    
    @Published private(set) var isPaidAccount: Bool = false
    @Published private(set) var rubbishBinAutopurgePeriod = 0
    @Published private(set) var isLoading = false
    @Published private(set) var selectedAutoPurgePeriod: AutoPurgePeriod = .none
    @Published private(set) var autoPurgePeriodDisplayName = ""
    @Published private(set) var autoPurgePeriods = [AutoPurgePeriod]()
    @Published var snackBar: SnackBar?
    
    var emptyRubbishBinTask: Task<Void, Never>?
    var updateAutoPurgeTask: Task<Void, Never>?
    
    @Published var isBottomSheetPresented = false
    
    // MARK: - Life Cycle
    
    init(accountUseCase: some AccountUseCaseProtocol,
         rubbishBinSettingsUseCase: some RubbishBinSettingsUseCaseProtocol,
         upgradeAccountRouter: some UpgradeAccountRouting = UpgradeAccountRouter()) {
        self.accountUseCase = accountUseCase
        self.rubbishBinSettingsUseCase = rubbishBinSettingsUseCase
        self.upgradeAccountRouter = upgradeAccountRouter
        
        isPaidAccount = accountUseCase.isPaidAccount
        autoPurgePeriods = AutoPurgePeriod.options(forPaidAccount: isPaidAccount)
    }
    
    deinit {
        emptyRubbishBinTask?.cancel()
        updateAutoPurgeTask?.cancel()
    }
    
    // MARK: Monitor Settings Change
    
    func startRubbishBinSettingsUpdatesMonitoring() async {
        for await resultRequest in rubbishBinSettingsUseCase.onRubbishBinSettinghsRequestFinish {
            try? Task.checkCancellation()
            
            handleRequestResult(resultRequest)
        }
    }
    
    // MARK: Internal
    
    func displayName(of period: AutoPurgePeriod) -> String {
        switch period {
        case .days(let days):
            Strings.Localizable.Settings.FileManagement.RubbishBin.AutoPurge.days(days)
        case .years(let years):
            Strings.Localizable.General.Format.RetentionPeriod.year(years)
        case .never:
            Strings.Localizable.never
        case .none: ""
        }
    }
    
    // MARK: Actions
    
    func onTapUpgradeButtton() {
        upgradeAccountRouter.presentUpgradeTVC()
    }
    
    func onTapAutoPurgeCell() {
        isBottomSheetPresented = true
    }
    
    func onTapAutoPurgeRow(with period: AutoPurgePeriod) {
        selectedAutoPurgePeriod = period
        isBottomSheetPresented = false
        
        updateAutoPurgeTask?.cancel()
        updateAutoPurgeTask = Task { [weak self] in
            guard let self else { return }
            
            let days = period.durationInDays ?? 7
            await rubbishBinSettingsUseCase.setRubbishBinAutopurgePeriod(in: days)
            
            rubbishBinAutopurgePeriod = days
            autoPurgePeriodDisplayName = displayName(of: period)
        }
    }
    
    func onTapEmptyBinButton() {
        guard MEGAReachabilityManager.isReachableHUDIfNot(), !isLoading else { return }
        
        isLoading = true
        
        emptyRubbishBinTask?.cancel()
        emptyRubbishBinTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await rubbishBinSettingsUseCase.cleanRubbishBin()
                try await rubbishBinSettingsUseCase.catchupWithSDK()
                
                try Task.checkCancellation()
                
                showSnackBar(message: Strings.Localizable.Settings.FileManagement.RubbishBin.Snackbar.message)
            } catch {
                CrashlyticsLogger.log(category: .general, "Empty Rubbish Bin had error.")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Private
    
    private func showSnackBar(message: String) {
        snackBar = .init(message: message)
    }
    
    private func handleRequestResult(_ result: Result<RubbishBinSettingsEntity, any Error>) {
        guard case .success(let entity) = result else { return }
        
        rubbishBinAutopurgePeriod = entity.rubbishBinAutopurgePeriod
        let autoPurgePeriod = AutoPurgePeriod(fromDays: Int(rubbishBinAutopurgePeriod))
        selectedAutoPurgePeriod = autoPurgePeriod
        
        autoPurgePeriodDisplayName = autoPurgePeriod == .none
        ? Strings.Localizable.Settings.FileManagement.RubbishBin.AutoPurge.days(rubbishBinAutopurgePeriod)
        : displayName(of: autoPurgePeriod)
    }
}
