import Foundation
import MEGADomain
import MEGAPreference

@MainActor
final class HomePromotionalDialogViewModel: ObservableObject {
    @PreferenceWrapper(key: PreferenceKeyEntity.homePromotionalDialogShown, defaultValue: false)
    private var hasShownDialog: Bool

    @Published var isPresented = false
    @Published var shouldNavigateToCustomizationAfterDismissal = false

    var shouldShowDialog: Bool {
        !hasShownDialog
    }

    init(preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        $hasShownDialog.useCase = preferenceUseCase
    }

    func presentIfNeeded(featureEnabled: Bool) {
        guard featureEnabled, shouldShowDialog else { return }
        hasShownDialog = true
        isPresented = true
    }

    func handleExplore() {
        shouldNavigateToCustomizationAfterDismissal = true
        isPresented = false
    }

    func handleDismiss() {
        isPresented = false
    }
}
