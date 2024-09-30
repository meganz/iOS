import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

typealias AdMobUnitID = String

final public class AdsSlotViewModel: ObservableObject {
    private var abTestProvider: any ABTestProviderProtocol
    private var adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private(set) var adMobConsentManager: any GoogleMobileAdsConsentManagerProtocol
    
    private(set) var adsSlotConfig: AdsSlotConfig?
    @Published var displayAds: Bool = false
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var isExternalAdsEnabled: Bool = false
    let refreshAdsSourcePublisher = PassthroughSubject<Void, Never>()
    public var refreshAdsPublisher: AnyPublisher<Void, Never> {
        refreshAdsSourcePublisher.eraseToAnyPublisher()
    }
    
    /// In the future, adMob will have multiple unit ids per adSlot
    let adMobUnitID: AdMobUnitID = "ca-app-pub-3940256099942544/2435281174"

    public init(
        adsSlotChangeStream: some AdsSlotChangeStreamProtocol,
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = GoogleMobileAdsConsentManager.shared
    ) {
        self.adsSlotChangeStream = adsSlotChangeStream
        self.abTestProvider = abTestProvider
        self.adMobConsentManager = adMobConsentManager
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
        
        try? await adMobConsentManager.gatherConsent()
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
}
