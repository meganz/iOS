import Combine
import Foundation
import MEGADomain
import MEGAPresentation

final public class TermsAndPoliciesViewModel: ObservableObject {
    private let accountUseCase: any AccountUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var abTestProvider: any ABTestProviderProtocol
    
    let privacyUrl = URL(string: "https://mega.io/privacy") ?? URL(fileURLWithPath: "")
    let termsUrl = URL(string: "https://mega.io/terms") ?? URL(fileURLWithPath: "")
    @Published var cookieUrl = URL(fileURLWithPath: "")
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider
    ) {
        self.accountUseCase = accountUseCase
        self.featureFlagProvider = featureFlagProvider
        self.abTestProvider = abTestProvider
    }
    
    // MARK: - Cookie policy
    private var isInAppAdvertisementEnabled: Bool { true }
    
    @MainActor
    func setupCookiePolicyURL() async {
        guard let cookiePolicyURL = URL(string: "https://mega.nz/cookie") else { return }
        
        guard isInAppAdvertisementEnabled else {
            cookieUrl = cookiePolicyURL
            return
        }
        
        let isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
        let isExternalAdsEnabled = await abTestProvider.abTestVariant(for: .externalAds) == .variantA
        guard isAdsEnabled && isExternalAdsEnabled else {
            cookieUrl = cookiePolicyURL
            return
        }
        
        do {
            let cookiePath = cookiePolicyURL.lastPathComponent
            cookieUrl = try await accountUseCase.sessionTransferURL(path: cookiePath)
        } catch {
            cookieUrl = URL(fileURLWithPath: "")
        }
    }
}
