import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final public class AdsSlotViewModel: ObservableObject {
    private let abTestProvider: any ABTestProviderProtocol
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
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = GoogleMobileAdsConsentManager.shared,
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = AppEnvironmentUseCase.shared
    ) {
        self.adsSlotChangeStream = adsSlotChangeStream
        self.abTestProvider = abTestProvider
        self.adMobConsentManager = adMobConsentManager
        self.appEnvironmentUseCase = appEnvironmentUseCase
    }

    // MARK: Setup
    @MainActor
    func setupSubscriptions() {
        NotificationCenter.default
            .publisher(for: .accountDidPurchasedPlan)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updateAdsSlot()
            }
            .store(in: &subscriptions)
    }

    func initializeGoogleAds() async {
        guard isExternalAdsEnabled else { return }
        await adMobConsentManager.initializeGoogleMobileAdsSDK()
    }

    // MARK: AB Test
    @MainActor
    func setupABTestVariant() async {
        isExternalAdsEnabled = await abTestProvider.abTestVariant(for: .externalAds) == .variantA
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
