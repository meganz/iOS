import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import SwiftUI

@MainActor
final public class AdsSlotViewModel: ObservableObject {
    private let adsUseCase: any AdsUseCaseProtocol
    private let nodeUseCase: (any NodeUseCaseProtocol)?
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
    private let publicNodeLink: String?
    private let isFolderLink: Bool
    
    @PreferenceWrapper(key: .lastCloseAdsButtonTappedDate, defaultValue: nil)
    private(set) var lastCloseAdsDate: Date?
    private let currentDate: @Sendable () -> Date
    
    public init(
        adsSlotUpdatesProvider: some AdsSlotUpdatesProviderProtocol,
        adsUseCase: some AdsUseCaseProtocol,
        nodeUseCase: (any NodeUseCaseProtocol)? = nil,
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
        publicNodeLink: String? = nil,
        isFolderLink: Bool,
        logger: ((String) -> Void)? = nil
    ) {
        self.adsSlotUpdatesProvider = adsSlotUpdatesProvider
        self.adsUseCase = adsUseCase
        self.nodeUseCase = nodeUseCase
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
        self.publicNodeLink = publicNodeLink
        self.isFolderLink = isFolderLink
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
                    await determineAdsAvailability()
                    
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

    // MARK: Ads Flag
    
    /// Determines whether ads should be enabled based on user account status and public link queries.
    func determineAdsAvailability() async {
        // Check if the user is logged in and has a paid account.
        // Ads should only be shown if the user is either logged out or has a free account.
        if accountUseCase.isLoggedIn(),
           let accountDetails = try? await accountUseCase.refreshCurrentAccountDetails(),
           accountDetails.proLevel != .free {
            isExternalAdsEnabled = false
            return
        }
        
        // Check if the ads is enabled via the remote feature flag.
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds) else {
            isExternalAdsEnabled = false
            return
        }

        // If ads are enabled and public node link is present, check for a public node link.
        if let publicNodeLink = publicNodeLink {
            if isFolderLink {
                if let folderInfo = try? await nodeUseCase?.folderLinkInfo(publicNodeLink) {
                    isExternalAdsEnabled = await shouldShowAdsFromPublicHandle(folderInfo.nodeHandle)
                    return
                }
            } else {
                if let urlLink = URL(string: publicNodeLink),
                   let node = try? await nodeUseCase?.nodeForFileLink(FileLinkEntity(linkURL: urlLink)) {
                    isExternalAdsEnabled = await shouldShowAdsFromPublicHandle(node.handle)
                    return
                }
            }
        }
        
        // Enable external ads by default if all checkers are not satisfied.
        isExternalAdsEnabled = true
    }
    
    /// Determines whether ads should be displayed for a given public handle.
    ///
    /// - Parameter handle: The HandleEntity representing the public file or folder.
    /// - Returns: true if ads should be shown, false if ads should not be displayed.
    /// - Note:
    ///   - If queryAds returns 1, ads should not be shown.
    ///   - If any error occurs, ads are enabled by default.
    private func shouldShowAdsFromPublicHandle(_ handle: HandleEntity) async -> Bool {
        do {
            let queryResult = try await adsUseCase.queryAds(adsFlag: .defaultAds, publicHandle: handle)
            let showAdsResult = 0
            return queryResult == showAdsResult
        } catch {
            return true
        }
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
