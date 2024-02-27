import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

final public class AdsSlotViewModel: ObservableObject {
    private var adsUseCase: any AdsUseCaseProtocol
    private var accountUseCase: any AccountUseCaseProtocol
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private var abTestProvider: any ABTestProviderProtocol
    private var adsSlotChangeStream: any AdsSlotChangeStreamProtocol
    private var adsSlotConfig: AdsSlotConfig?
    private var isAdsEnabled: Bool = false
    
    @Published var adsUrl: URL?
    @Published var displayAds: Bool = false
    private(set) var closedAds: Set<AdsSlotEntity> = []
    
    private(set) var monitorAdsSlotChangesTask: Task<Void, Never>?
    private(set) var hideAdsForUpgradedAccountTask: Task<Void, Never>?
    private(set) var loadNewAdsTask: Task<Void, Never>?
    
    private var subscriptions = Set<AnyCancellable>()
    
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
        hideAdsForUpgradedAccountTask?.cancel()
        hideAdsForUpgradedAccountTask = nil
        loadNewAdsTask?.cancel()
        loadNewAdsTask = nil
    }
    
    // MARK: Setup
    func setupSubscriptions() {
        NotificationCenter.default
            .publisher(for: .accountDidPurchasedPlan)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                hideAdsForUpgradedAccount()
            }
            .store(in: &subscriptions)
    }
    
    // MARK: Upgraded Account notif
    private func hideAdsForUpgradedAccount() {
        hideAdsForUpgradedAccountTask = Task { [weak self] in
            guard let self else { return }
            await updateAdsSlot(nil)
        }
    }
    
    // MARK: Feature Flag
    var isInAppAdvertisementEnabled: Bool { true }
    
    // MARK: AB Test
    func setupABTestVariant() async {
        isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
    }
    
    // MARK: Ads
    func monitorAdsSlotChanges() {
        guard monitorAdsSlotChangesTask == nil else { return }
        
        monitorAdsSlotChangesTask = Task { [weak self] in
            guard let self else { return }
            for await newAdsSlotConfig in adsSlotChangeStream.adsSlotStream {
                await updateAdsSlot(newAdsSlotConfig)
            }
        }
    }
    
    func updateAdsSlot(_ newAdsSlotConfig: AdsSlotConfig?) async {
        guard isInAppAdvertisementEnabled, isAdsEnabled else {
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
            await displayAds(newAdsSlotConfig.displayAds && adsUrl != nil)
        } else {
            adsSlotConfig = newAdsSlotConfig
            loadNewAds()
        }
    }
    
    private func loadNewAds() {
        loadNewAdsTask?.cancel()
        
        loadNewAdsTask = Task { [weak self] in
            guard let self = self else { return }
            guard isInAppAdvertisementEnabled, let adsSlotConfig, isAdsEnabled else {
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
                
                let adsURLString = await appendAdCookieStatusToURL(url: adsValue)
                
                await configureAds(url: URL(string: adsURLString), shouldDisplayAds: adsSlotConfig.displayAds)
            } catch {
                await configureAds(url: nil)
            }
        }
    }
    
    func appendAdCookieStatusToURL(url: String) async -> String {
        let isAdsCookieEnabled = await adsSlotConfig?.isAdsCookieEnabled()
        let adCookieParameter = isAdsCookieEnabled == true ? "1" : "0"
        // Considering the scenario where the first parameter is added using a ? instead of an &
        let separator = url.contains("?") ? "&" : "?"
        return url + separator + "ac=" + adCookieParameter
    }
    
    func didTapAdsContent() async {
        guard accountUseCase.isNewAccount else {
            // For existing users, new ads will be loaded for the current ads slot
            loadNewAds()
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
        guard !Task.isCancelled else { return }
        adsUrl = url
        displayAds(shouldDisplayAds)
    }
    
    @MainActor
    private func displayAds(_ shouldDisplayAds: Bool) {
        guard !Task.isCancelled else { return }
        displayAds = shouldDisplayAds
    }
}
