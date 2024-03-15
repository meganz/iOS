import MEGADomain
import MEGAPresentation

protocol CallWillEndAlertRouting: Routing {
    func showCallWillEndAlert(upgradeAction: @escaping () -> Void, notNowAction: @escaping () -> Void)
    func updateCallWillEndAlertTitle(remainingMinutes: Int)
    func showUpgradeAccount(_ account: AccountDetailsEntity)
    func dismissCallWillEndAlertIfNeeded()
}

class CallWillEndAlertViewModel {
    private let router: any CallWillEndAlertRouting
    private let accountUseCase: any AccountUseCaseProtocol
    private var remainingSeconds: Int

    private var callWillEndTimer: Timer?
    
    private var dismissCompletion: ((Int) -> Void)?

    init(router: any CallWillEndAlertRouting,
         accountUseCase: any AccountUseCaseProtocol,
         remainingSeconds: Int,
         dismissCompletion: ((Int) -> Void)?) {
        self.router = router
        self.accountUseCase = accountUseCase
        self.remainingSeconds = remainingSeconds
        self.dismissCompletion = dismissCompletion
    }
    
    func viewReady() {
        showCallWillEndAlert()
    }
    
    private func showCallWillEndAlert() {
        router.showCallWillEndAlert { [weak self] in
            guard let self, let accountDetails = accountUseCase.currentAccountDetails else { return }
            callWillEndTimer?.invalidate()
            dismissCompletion?(remainingSeconds)
            router.showUpgradeAccount(accountDetails)
        } notNowAction: { [weak self] in
            guard let self else { return }
            callWillEndTimer?.invalidate()
            dismissCompletion?(remainingSeconds)
        }
        router.updateCallWillEndAlertTitle(remainingMinutes: remainingSecondsCountRoundedUp())
        startCallWillEndTimer()
    }
    
    private func startCallWillEndTimer() {
        callWillEndTimer?.invalidate()
        callWillEndTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            remainingSeconds -= 1
            guard remainingSeconds > 0 else { return }
            router.updateCallWillEndAlertTitle(remainingMinutes: remainingSecondsCountRoundedUp())
        })
    }
    
    private func remainingSecondsCountRoundedUp() -> Int {
        Int((Double(remainingSeconds)/60.0).rounded(.up))
    }
}
