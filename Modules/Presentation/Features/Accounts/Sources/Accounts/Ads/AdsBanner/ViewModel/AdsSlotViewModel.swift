import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import SwiftUI

@MainActor
final public class AdsSlotViewModel: ObservableObject {
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let adsSlotUpdatesProvider: any AdsSlotUpdatesProviderProtocol
    private let adMobConsentManager: any GoogleMobileAdsConsentManagerProtocol
    private let appEnvironmentUseCase: any AppEnvironmentUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    public let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private(set) var logger: ((String) -> Void)?
    
    private(set) var adsSlotConfig: AdsSlotConfig?
    private(set) var monitorAdsSlotUpdatesTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var startAds: Bool = false
    @Published var isExternalAdsEnabled: Bool?
    @Published var displayAds: Bool = false
    @Published var showCloseButton: Bool = false
    @Published var showAdsFreeView: Bool = false
    private(set) var onViewFirstAppeared: (() -> Void)?
    public let adsFreeViewProPlanAction: (() -> Void)?
    private let notificationCenter: NotificationCenter
    
    @PreferenceWrapper(key: .lastCloseAdsButtonTappedDate, defaultValue: nil)
    private(set) var lastCloseAdsDate: Date?
    private let currentDate: @Sendable () -> Date
    
    public init(
        adsSlotUpdatesProvider: some AdsSlotUpdatesProviderProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = GoogleMobileAdsConsentManager.shared,
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = AppEnvironmentUseCase.shared,
        accountUseCase: some AccountUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        onViewFirstAppeared: (() -> Void)? = nil,
        adsFreeViewProPlanAction: (() -> Void)? = nil,
        currentDate: @escaping @Sendable () -> Date = { Date() },
        notificationCenter: NotificationCenter = .default,
        logger: ((String) -> Void)? = nil
    ) {
        self.adsSlotUpdatesProvider = adsSlotUpdatesProvider
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.adMobConsentManager = adMobConsentManager
        self.appEnvironmentUseCase = appEnvironmentUseCase
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.tracker = tracker
        self.onViewFirstAppeared = onViewFirstAppeared
        self.adsFreeViewProPlanAction = adsFreeViewProPlanAction
        self.currentDate = currentDate
        self.notificationCenter = notificationCenter
        self.logger = logger
        
        $lastCloseAdsDate.useCase = preferenceUseCase
        registerDelegates()
    }

    // MARK: Setup
    deinit {
        Task { [purchaseUseCase] in
            await purchaseUseCase.deRegisterPurchaseDelegate()
        }
    }
    
    private func registerDelegates() {
        Task { [purchaseUseCase] in
            await purchaseUseCase.registerPurchaseDelegate()
        }
    }
    
    func setupSubscriptions() {
        notificationCenter
            .publisher(for: .accountDidPurchasedPlan)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, isExternalAdsEnabled == true else { return }
                
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    isExternalAdsEnabled = false
                    showAdsFreeView = false
                    displayAds = false
                }
            }
            .store(in: &subscriptions)
        
        purchaseUseCase.submitReceiptResultPublisher
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self, case .failure = result else { return }
                
                // For failed receipt submission, check if ads should appear.
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await setupAdsRemoteFlag()
                    
                    if isExternalAdsEnabled == true {
                        displayAds = adsSlotConfig?.displayAds ?? false
                    } else {
                        displayAds = false
                    }
                }
            }
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: .startAds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                startAds = true   
            }
            .store(in: &subscriptions)
    }

    // MARK: Remote Feature Flag
    func setupAdsRemoteFlag() async {
        // Check for enabled external ads only if there is no logged in user or the account type is free
        if accountUseCase.isLoggedIn(),
           let accountDetails = try? await accountUseCase.refreshCurrentAccountDetails(),
           accountDetails.proLevel != .free {
            isExternalAdsEnabled = false
            return
        }
        isExternalAdsEnabled = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
    }
    
    // MARK: Ads Slot changes
    func startMonitoringAdsSlotUpdates() {
        monitorAdsSlotUpdatesTask?.cancel()
        monitorAdsSlotUpdatesTask = Task { [weak self, adsSlotUpdatesProvider] in
            for await newAdsSlotConfig in adsSlotUpdatesProvider.adsSlotUpdates {
                self?.updateAdsSlot(newAdsSlotConfig)
            }
        }
    }
    
    func stopMonitoringAdsSlotUpdates() {
        monitorAdsSlotUpdatesTask?.cancel()
    }
    
    func updateAdsSlot(_ newAdsSlotConfig: AdsSlotConfig? = nil) {
        if let isExternalAdsEnabled {
            guard isExternalAdsEnabled else {
                adsSlotConfig = nil
                displayAds = false
                return
            }
            
            guard adsSlotConfig != newAdsSlotConfig else {
                return
            }
        }
        
        adsSlotConfig = newAdsSlotConfig
        displayAds = newAdsSlotConfig?.displayAds ?? false
    }
    
    /// In the future, AdMob will have multiple unit ids per adSlot
    public var adMob: AdMob {
        appEnvironmentUseCase.configuration == .production ? AdMob.live : AdMob.test
    }
    
    // MARK: Close Ads button
    func bannerViewDidReceiveAdsUpdate(result: Result<Void, any Error>) {
        switch result {
        case .success:
            logger?("[AdMob] Ads Banner did received ad")
        
            // Show close button only when a user is logged in, otherwise, hide button
            showCloseButton = accountUseCase.isLoggedIn()
        case .failure(let error):
            logger?("[AdMob] Ads Banner failed to receive ad with error \(error.localizedDescription)")
        }
    }
    
    func didTapCloseAdsButton() {
        lastCloseAdsDate = currentDate()
        showAdsFreeView = true
        tracker.trackAnalyticsEvent(with: AdsBannerCloseAdsButtonPressedEvent())
    }
}
