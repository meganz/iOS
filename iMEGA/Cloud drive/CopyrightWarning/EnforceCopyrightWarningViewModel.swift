import Combine
import Foundation
import MEGADomain
import MEGAL10n

@MainActor
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
    private var agreedCopyrightWarning: Bool
    private var subscriptions = Set<AnyCancellable>()
    
    var copyrightMessage: String {
        "\(Strings.Localizable.copyrightMessagePart1)\n\n\(Strings.Localizable.copyrightMessagePart2)"
    }
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         copyrightUseCase: some CopyrightUseCaseProtocol) {
        self.copyrightUseCase = copyrightUseCase
        $agreedCopyrightWarning.useCase = preferenceUseCase
        subscribeToTermsAgreed()
    }
    
    func determineViewState() async {
        if agreedCopyrightWarning {
            viewStatus = .agreed
        } else {
            await checkCopyrightAgreedBefore()
        }
    }
    
    private func checkCopyrightAgreedBefore() async {
        if await copyrightUseCase.shouldAutoApprove() {
            agreeToCopyright()
        } else {
            viewStatus = .declined
        }
    }
    
    private func agreeToCopyright() {
        agreedCopyrightWarning = true
        viewStatus = .agreed
    }
    
    private func subscribeToTermsAgreed() {
        $isTermsAgreed
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                agreeToCopyright()
            }.store(in: &subscriptions)
    }
}
