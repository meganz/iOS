import MEGADomain

@MainActor
protocol OverDiskQuotaChecking {
    func showOverDiskQuotaIfNeeded() -> Bool
}

struct OverDiskQuotaChecker: OverDiskQuotaChecking {
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let appDelegateRouter: any AppDelegateRouting
    
    init(
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        appDelegateRouter: some AppDelegateRouting
    ) {
        self.accountStorageUseCase = accountStorageUseCase
        self.appDelegateRouter = appDelegateRouter
    }
    
    func showOverDiskQuotaIfNeeded() -> Bool {
        if accountStorageUseCase.isPaywalled {
            appDelegateRouter.showOverDiskQuota()
            return true
        }
        return false
    }
}
