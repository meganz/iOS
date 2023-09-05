import Combine
import Foundation
import MEGADomain
import MEGAL10n

final class EnforceCopyrightWarningViewModel: ObservableObject {
    enum CopyrightWarningViewStatus {
        case unknown
        case agreed
        case declined
    }
    
    @Published var viewStatus: CopyrightWarningViewStatus = .unknown
    @Published var isTermsAgreed: Bool = false
    
    private let copyrightUseCase: any CopyrightUseCaseProtocol
    @PreferenceWrapper(key: .agreedCopywriteWarning, defaultValue: false)
    private var agreedCopywriteWarning: Bool
    private var subscriptions = Set<AnyCancellable>()
    
    var copyrightMessage: String {
        "\(Strings.Localizable.copyrightMessagePart1)\n\n\(Strings.Localizable.copyrightMessagePart2)"
    }
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         copyrightUseCase: some CopyrightUseCaseProtocol) {
        self.copyrightUseCase = copyrightUseCase
        $agreedCopywriteWarning.useCase = preferenceUseCase
        subscribeToTermsAggreed()
    }
    
    @MainActor
    func determineViewState() async {
        if agreedCopywriteWarning {
            viewStatus = .agreed
        } else {
            await checkCopyrightAgreedBefore()
        }
    }
    
    @MainActor
    private func checkCopyrightAgreedBefore() async {
        if await copyrightUseCase.shouldAutoApprove() {
            agreeToCopyright()
        } else {
            viewStatus = .declined
        }
    }
    
    @MainActor
    private func agreeToCopyright() {
        agreedCopywriteWarning = true
        viewStatus = .agreed
    }
    
    private func subscribeToTermsAggreed() {
        $isTermsAgreed
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                Task { [weak self] in
                    await self?.agreeToCopyright()
                }
            }.store(in: &subscriptions)
    }
}
