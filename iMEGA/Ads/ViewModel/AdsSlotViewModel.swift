import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final class AdsSlotViewModel: ObservableObject {
    private var adsUseCase: any AdsUseCaseProtocol
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private var adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private var adsSlot: AdsSlotEntity?
    
    @Published var adsUrl: URL?
    @Published var displayAds: Bool = false
    
    init(adsUseCase: some AdsUseCaseProtocol,
         adsSlotChangeStream: some AdsSlotChangeStreamProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.adsUseCase = adsUseCase
        self.adsSlotChangeStream = adsSlotChangeStream
        self.featureFlagProvider = featureFlagProvider
    }

    func monitorAdsSlotChanges() async {
        guard let adsSlotStream = adsSlotChangeStream.adsSlotStream else { return }
        
        for await newAdsSlot in adsSlotStream {
            guard adsSlot != newAdsSlot else { return }
            
            adsSlot = newAdsSlot
            await loadAds()
        }
    }
    
    // MARK: Feature Flag
    var isFeatureFlagForInAppAdsEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .inAppAds)
    }
    
    // MARK: Ads
    func loadAds() async {
        guard let adsSlot, isFeatureFlagForInAppAdsEnabled else {
            await setAdsUrl(nil)
            return
        }
        
        do {
            let adsResult = try await adsUseCase.fetchAds(adsFlag: .forceAds,
                                                          adUnits: [adsSlot],
                                                          publicHandle: .invalidHandle)
            guard let adsValue = adsResult[adsSlot.rawValue] else {
                await setAdsUrl(nil)
                MEGALogInfo("[Ads] No ads for adSlot \(adsSlot.rawValue)")
                return
            }
            
            await setAdsUrl(URL(string: adsValue))
            MEGALogInfo("[Ads] Fetched new ads")
        } catch {
            MEGALogError("[Ads] Can't fetch ads with error \(error.localizedDescription)")
            await setAdsUrl(nil)
        }
    }
    
    @MainActor
    private func setAdsUrl(_ url: URL?) {
        guard let url else {
            adsUrl = nil
            displayAds = false
            return
        }
        
        adsUrl = url
        displayAds = true
    }
}
