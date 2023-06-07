import Foundation
import MEGADomain
import Combine

final class EnforceCopyrightWarningViewModel: ObservableObject {
    enum CopyrightWarningViewStatus {
        case unknown
        case agreed
        case declined
    }
    
    @Published var viewStatus: CopyrightWarningViewStatus = .unknown
    @Published var isTermsAggreed: Bool = false
    
    private let shareUseCase: ShareUseCaseProtocol
    @PreferenceWrapper(key: .agreedCopywriteWarning, defaultValue: false)
    private var agreedCopywriteWarning: Bool
    private var subscriptions = Set<AnyCancellable>()
    
    var copyrightMessage: String {
        "\(Strings.Localizable.copyrightMessagePart1)\n\n\(Strings.Localizable.copyrightMessagePart2)"
    }
    
    init(preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default,
         shareUseCase: ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
        $agreedCopywriteWarning.useCase = preferenceUseCase
        subscribeToTermsAggreed()
    }
    
    func determineViewState() {
        setAgreedIfAccountContainsSharedLinks()
        if agreedCopywriteWarning {
            viewStatus = .agreed
        } else {
            viewStatus = .declined
        }
    }
    
    private func setAgreedIfAccountContainsSharedLinks() {
        if !agreedCopywriteWarning,
           shareUseCase.allPublicLinks(sortBy: .none).isNotEmpty {
            agreedCopywriteWarning = true
        }
    }
    
    private func subscribeToTermsAggreed() {
        $isTermsAggreed
            .dropFirst()
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                agreedCopywriteWarning = true
                viewStatus = .agreed
            }.store(in: &subscriptions)
    }
}
