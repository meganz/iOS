import Combine
import Foundation
import MEGADomain
import MEGAPresentation

final public class TermsAndPoliciesViewModel: ObservableObject {
    private let accountUseCase: any AccountUseCaseProtocol
    private var abTestProvider: any ABTestProviderProtocol
    
    let privacyUrl = URL(string: "https://mega.io/privacy") ?? URL(fileURLWithPath: "")
    let termsUrl = URL(string: "https://mega.io/terms") ?? URL(fileURLWithPath: "")
    @Published var cookieUrl = URL(fileURLWithPath: "")
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider
    ) {
        self.accountUseCase = accountUseCase
        self.abTestProvider = abTestProvider
    }
    
    // MARK: - Cookie policy
    @MainActor
    func setupCookiePolicyURL() async {
        guard let cookiePolicyURL = URL(string: "https://mega.nz/cookie") else { return }
        
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
