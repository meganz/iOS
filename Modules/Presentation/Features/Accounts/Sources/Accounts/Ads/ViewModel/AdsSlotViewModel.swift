import Combine
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import SwiftUI

final public class AdsSlotViewModel: ObservableObject {
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private let adMobConsentManager: any GoogleMobileAdsConsentManagerProtocol
    private let appEnvironmentUseCase: any AppEnvironmentUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    
    private(set) var adsSlotConfig: AdsSlotConfig?
    private(set) var monitorAdsSlotChangesTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var isExternalAdsEnabled: Bool = false
    @Published var displayAds: Bool = false
    
    public init(
        adsSlotChangeStream: some AdsSlotChangeStreamProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = GoogleMobileAdsConsentManager.shared,
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = AppEnvironmentUseCase.shared,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.adsSlotChangeStream = adsSlotChangeStream
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.adMobConsentManager = adMobConsentManager
        self.appEnvironmentUseCase = appEnvironmentUseCase
        self.accountUseCase = accountUseCase
    }
    
    deinit {
        monitorAdsSlotChangesTask?.cancel()
        monitorAdsSlotChangesTask = nil
    }

    // MARK: Setup
    func setupSubscriptions() {
        NotificationCenter.default
            .publisher(for: .accountDidPurchasedPlan)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, isExternalAdsEnabled else { return }
                
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    isExternalAdsEnabled = false
                    updateAdsSlot()
                }
            }
            .store(in: &subscriptions)
    }

    func initializeGoogleAds() async {
        guard isExternalAdsEnabled else { return }
        await adMobConsentManager.initializeGoogleMobileAdsSDK()
    }

    // MARK: Remote Flag
    @MainActor
    func setupAdsRemoteFlag() async {
        // Check for enabled external ads only if there is no logged in user or the account type is free
        if accountUseCase.isLoggedIn(),
           let accountDetails = try? await accountUseCase.refreshCurrentAccountDetails(),
           accountDetails.proLevel != .free {
            isExternalAdsEnabled = false
            return
        }
        isExternalAdsEnabled = await remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
    }
    
    // MARK: Ads Slot changes
    func monitorAdsSlotChanges() {
        monitorAdsSlotChangesTask = Task { [weak self] in
            guard let self else { return }
            for await newAdsSlotConfig in adsSlotChangeStream.adsSlotStream {
                if Task.isCancelled { return }
                await updateAdsSlot(newAdsSlotConfig)
            }
        }
    }
    
    @MainActor
    func updateAdsSlot(_ newAdsSlotConfig: AdsSlotConfig? = nil) {
        guard isExternalAdsEnabled else {
            adsSlotConfig = nil
            displayAds = false
            return
        }
        
        guard adsSlotConfig != newAdsSlotConfig else {
            return
        }
        
        adsSlotConfig = newAdsSlotConfig
        displayAds = newAdsSlotConfig?.displayAds ?? false
    }
    
    /// In the future, AdMob will have multiple unit ids per adSlot
    public var adMob: AdMob {
        appEnvironmentUseCase.configuration == .production ? AdMob.live : AdMob.test
    }
}
