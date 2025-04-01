import MEGAAppPresentation
import MEGADomain

protocol CallWillEndAlertRouting: Routing {
    func showCallWillEndAlert(upgradeAction: @escaping () -> Void, notNowAction: @escaping () -> Void)
    func updateCallWillEndAlertTitle(remainingMinutes: Int)
    func showUpgradeAccount(_ account: AccountDetailsEntity)
    func dismissCallWillEndAlertIfNeeded()
}

class CallWillEndAlertViewModel {
    private let router: any CallWillEndAlertRouting
    private let accountUseCase: any AccountUseCaseProtocol
    private var timeToEndCall: Double

    private var callWillEndTimer: Timer?
    
    private var dismissCompletion: ((Double) -> Void)?

    init(router: any CallWillEndAlertRouting,
         accountUseCase: any AccountUseCaseProtocol,
         timeToEndCall: Double,
         dismissCompletion: ((Double) -> Void)?) {
        self.router = router
        self.accountUseCase = accountUseCase
        self.timeToEndCall = timeToEndCall
        self.dismissCompletion = dismissCompletion
    }
    
    func viewReady() {
        showCallWillEndAlert()
    }
    
    private func showCallWillEndAlert() {
        router.showCallWillEndAlert { [weak self] in
            guard let self, let accountDetails = accountUseCase.currentAccountDetails else { return }
            callWillEndTimer?.invalidate()
            dismissCompletion?(timeToEndCall)
            router.showUpgradeAccount(accountDetails)
        } notNowAction: { [weak self] in
            guard let self else { return }
            callWillEndTimer?.invalidate()
            dismissCompletion?(timeToEndCall)
        }
        router.updateCallWillEndAlertTitle(remainingMinutes: remainingSecondsCountRoundedUp())
        startCallWillEndTimer()
    }
    
    private func startCallWillEndTimer() {
        callWillEndTimer?.invalidate()
        callWillEndTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            timeToEndCall -= 1
            guard timeToEndCall > 0 else { return }
            router.updateCallWillEndAlertTitle(remainingMinutes: remainingSecondsCountRoundedUp())
        })
    }
    
    private func remainingSecondsCountRoundedUp() -> Int {
        Int((timeToEndCall/60.0).rounded(.up))
    }
}
