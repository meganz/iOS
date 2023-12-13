import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final public class AdsSlotViewModel: ObservableObject {
    enum AdsType {
        case external, none
    }
    
    private var adsUseCase: any AdsUseCaseProtocol
    private var accountUseCase: any AccountUseCaseProtocol
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private var abTestProvider: any ABTestProviderProtocol
    private var adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private var adsSlotConfig: AdsSlotConfig?
    private(set) var adsType: AdsType = .none
    
    @Published var adsUrl: URL?
    @Published var displayAds: Bool = false
    private(set) var closedAds: Set<AdsSlotEntity> = []
    
    private(set) var monitorAdsSlotChangesTask: Task<Void, Never>?
    
    public init(
        adsUseCase: some AdsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        adsSlotChangeStream: some AdsSlotChangeStreamProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider
    ) {
        self.adsUseCase = adsUseCase
        self.accountUseCase = accountUseCase
        self.adsSlotChangeStream = adsSlotChangeStream
        self.featureFlagProvider = featureFlagProvider
        self.abTestProvider = abTestProvider
    }
    
    deinit {
        monitorAdsSlotChangesTask?.cancel()
        monitorAdsSlotChangesTask = nil
    }
    
    // MARK: Feature Flag
    var isFeatureFlagForInAppAdsEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .inAppAds)
    }
    
    // MARK: AB Test
    func setupABTestVariant() async {
        let isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
        let isExternalAdsEnabled = await abTestProvider.abTestVariant(for: .externalAds) == .variantA
        
        guard isAdsEnabled, isExternalAdsEnabled else {
            adsType = .none
            return
        }

        adsType = .external
    }
    
    // MARK: Ads
    func monitorAdsSlotChanges() {
        guard monitorAdsSlotChangesTask == nil else { return }
        
        monitorAdsSlotChangesTask = Task {
            for await newAdsSlotConfig in adsSlotChangeStream.adsSlotStream {
                await updateAdsSlot(newAdsSlotConfig)
            }
        }
    }
    
    func updateAdsSlot(_ newAdsSlotConfig: AdsSlotConfig?) async {
        guard isFeatureFlagForInAppAdsEnabled && adsType != .none else {
            adsSlotConfig = nil
            await configureAds(url: nil)
            return
        }

        if let newAdsSlot = newAdsSlotConfig?.adsSlot, closedAds.contains(newAdsSlot) {
            self.adsSlotConfig = nil
            await displayAds(false)
            return
        }
        
        guard adsSlotConfig != newAdsSlotConfig else {
            return
        }
        
        if let adsSlotConfig,
           let newAdsSlotConfig,
            adsSlotConfig.adsSlot == newAdsSlotConfig.adsSlot {
            self.adsSlotConfig = newAdsSlotConfig
            await displayAds(newAdsSlotConfig.displayAds)
        } else {
            adsSlotConfig = newAdsSlotConfig
            await loadNewAds()
        }
    }
    
    func loadNewAds() async {
        guard let adsSlotConfig, isFeatureFlagForInAppAdsEnabled, adsType != .none else {
            await configureAds(url: nil)
            return
        }
        
        do {
            let adsSlot = adsSlotConfig.adsSlot
            let adsResult = try await adsUseCase.fetchAds(adsFlag: .defaultAds,
                                                          adUnits: [adsSlot],
                                                          publicHandle: .invalidHandle)
            guard let adsValue = adsResult[adsSlot.rawValue] else {
                await configureAds(url: nil)
                return
            }
            
            await configureAds(url: URL(string: adsValue), shouldDisplayAds: adsSlotConfig.displayAds)
        } catch {
            await configureAds(url: nil)
        }
    }
    
    func didTapAdsContent() async {
        guard accountUseCase.isNewAccount else {
            // For existing users, new ads will be loaded for the current ads slot
            await loadNewAds()
            return
        }
    
        // For new users, the ads will not show again on this ads slot
        guard let adsSlotConfig else { return }
        closedAds.insert(adsSlotConfig.adsSlot)

        self.adsSlotConfig = nil
        await displayAds(false)
    }
    
    @MainActor
    private func configureAds(url: URL?, shouldDisplayAds: Bool = false) {
        adsUrl = url
        displayAds(shouldDisplayAds)
    }
    
    @MainActor
    private func displayAds(_ shouldDisplayAds: Bool) {
        displayAds = shouldDisplayAds
    }
}
