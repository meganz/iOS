import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain

@MainActor
final public class TermsAndPoliciesViewModel: ObservableObject {
    private let accountUseCase: any AccountUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let domainNameHandler: () -> String
    private let router: any TermsAndPoliciesRouting
    
    let privacyUrl = URL(string: "https://mega.io/privacy") ?? URL(fileURLWithPath: "")
    let termsUrl = URL(string: "https://mega.io/terms") ?? URL(fileURLWithPath: "")
    @Published var cookieUrl = URL(fileURLWithPath: "")
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        domainNameHandler: @escaping () -> String,
        router: some TermsAndPoliciesRouting
    ) {
        self.accountUseCase = accountUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.domainNameHandler = domainNameHandler
        self.router = router
    }
    
    // MARK: - Cookie policy
    func setupCookiePolicyURL() async {
        guard let cookiePolicyURL = URL(string: "https://\(domainNameHandler())/cookie") else { return }

        let isExternalAdsEnabled = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
        guard isExternalAdsEnabled else {
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
    
    func dismiss() {
        router.dismiss()
    }
}
