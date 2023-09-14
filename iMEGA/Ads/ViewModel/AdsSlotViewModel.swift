import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final class AdsSlotViewModel: ObservableObject {
    private var adsUseCase: any AdsUseCaseProtocol
    private var accountUseCase: any AccountUseCaseProtocol
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private var adsSlot: AdsSlotEntity?
    private(set) var shouldShowAds: Bool = false
    
    @Published var adsUrl: URL?
    @Published var displayAds: Bool = false
    
    var fetchNewAdsTask: Task<Void, Never>?
    
    init(adsUseCase: some AdsUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         adsSlot: AdsSlotEntity?,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.adsUseCase = adsUseCase
        self.accountUseCase = accountUseCase
        self.adsSlot = adsSlot
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        fetchNewAdsTask?.cancel()
        fetchNewAdsTask = nil
    }
    
    var isFeatureFlagForInAppAdsEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .inAppAds)
    }
    
    func fetchAccountDetails() async -> AccountDetailsEntity? {
        if let details = accountUseCase.currentAccountDetails {
            return details
        } else {
            do {
                return try await accountUseCase.refreshCurrentAccountDetails()
            } catch {
                MEGALogError("[Ads] Can't fetch account details with error \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    func fetchNewAds() {
        fetchNewAdsTask = Task {
            await loadAds()
        }
    }
    
    func setUpAdSlot() async {
        guard let accountDetails = await fetchAccountDetails() else { return }
        
        shouldShowAds = accountDetails.proLevel == .free && isFeatureFlagForInAppAdsEnabled
    }
    
    func loadAds() async {
        guard let adsSlot, shouldShowAds else {
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
