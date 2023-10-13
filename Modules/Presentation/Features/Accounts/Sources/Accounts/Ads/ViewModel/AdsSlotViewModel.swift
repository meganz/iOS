import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final public class AdsSlotViewModel: ObservableObject {
    private var adsUseCase: any AdsUseCaseProtocol
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private var adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private var adsSlotConfig: AdsSlotConfig?
    
    @Published var adsUrl: URL?
    @Published var displayAds: Bool = false
    
    private(set) var monitorAdsSlotChangesTask: Task<Void, Never>?
    
    public init(
        adsUseCase: some AdsUseCaseProtocol,
        adsSlotChangeStream: some AdsSlotChangeStreamProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.adsUseCase = adsUseCase
        self.adsSlotChangeStream = adsSlotChangeStream
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        monitorAdsSlotChangesTask?.cancel()
        monitorAdsSlotChangesTask = nil
    }
    
    // MARK: Feature Flag
    var isFeatureFlagForInAppAdsEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .inAppAds)
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
        guard isFeatureFlagForInAppAdsEnabled else {
            adsSlotConfig = nil
            await configureAds(url: nil)
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
        guard let adsSlotConfig, isFeatureFlagForInAppAdsEnabled else {
            await configureAds(url: nil)
            return
        }
        
        do {
            let adsSlot = adsSlotConfig.adsSlot
            let adsResult = try await adsUseCase.fetchAds(adsFlag: .forceAds,
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
