import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final public class AdsSlotViewModel: ObservableObject {
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private let adMobConsentManager: any GoogleMobileAdsConsentManagerProtocol
    private let appEnvironmentUseCase: any AppEnvironmentUseCaseProtocol
    
    private(set) var adsSlotConfig: AdsSlotConfig?
    @Published var displayAds: Bool = false
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var isExternalAdsEnabled: Bool = false
    let refreshAdsSourcePublisher = PassthroughSubject<Void, Never>()
    public var refreshAdsPublisher: AnyPublisher<Void, Never> {
        refreshAdsSourcePublisher.eraseToAnyPublisher()
    }
    
    public init(
        adsSlotChangeStream: some AdsSlotChangeStreamProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = GoogleMobileAdsConsentManager.shared,
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = AppEnvironmentUseCase.shared
    ) {
        self.adsSlotChangeStream = adsSlotChangeStream
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.adMobConsentManager = adMobConsentManager
        self.appEnvironmentUseCase = appEnvironmentUseCase
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
        isExternalAdsEnabled = await remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
    }
    
    // MARK: Ads Slot changes
    func monitorAdsSlotChanges() async {
        for await newAdsSlotConfig in adsSlotChangeStream.adsSlotStream {
            await updateAdsSlot(newAdsSlotConfig)
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
        
        if let adsSlotConfig,
           let newAdsSlotConfig,
           adsSlotConfig.adsSlot == newAdsSlotConfig.adsSlot {
            self.adsSlotConfig = newAdsSlotConfig
            displayAds = newAdsSlotConfig.displayAds
        } else {
            adsSlotConfig = newAdsSlotConfig
            loadNewAds()
        }
    }
    
    @MainActor
    private func loadNewAds() {
        guard let adsSlotConfig, isExternalAdsEnabled else {
            displayAds = false
            return
        }
        
        refreshAdsSourcePublisher.send()
        
        displayAds = adsSlotConfig.displayAds
    }
    
    /// In the future, AdMob will have multiple unit ids per adSlot
    public var adMob: AdMob {
        appEnvironmentUseCase.configuration == .production ? AdMob.live : AdMob.test
    }
}
