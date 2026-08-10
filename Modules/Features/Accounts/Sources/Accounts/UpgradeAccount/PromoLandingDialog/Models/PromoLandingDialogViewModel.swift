import Combine

/// Drives the promotional offer landing dialog when it loads on screen: resolves the offer through
/// ``PromotedPlanUseCase`` and maps the outcome to a view state.
///
/// Only the user-triggered entry point needs this. A host that loads the offer before presenting
/// has no states to move through, and shows ``PromoLandingDialogContentView`` directly.
@MainActor
final class PromoLandingDialogViewModel: ObservableObject {
    enum ViewState {
        case loading
        case loaded(PromoLandingDialogContentView.Dependency)
        case error
    }

    @Published private(set) var viewState: ViewState = .loading

    private let dependency: PromoLandingDialogDependency

    init(dependency: PromoLandingDialogDependency) {
        self.dependency = dependency
    }

    func load() async {
        viewState = .loading

        do {
            guard let promotedPlan = try await dependency
                .promotedPlanUseCase
                .fetchPromotedPlan(checksForExpiry: dependency.checksForExpiry) else {
                // Nothing on offer and nothing to fall back to, so we show error
                // Ideally we should show something like "No offer to display", but this is design decision
                // and it's rarely happens so it's an acceptable compromise.
                viewState = .error
                return
            }

            viewState = .loaded(dependency.contentViewDependency(for: promotedPlan))
        } catch {
            viewState = .error
        }
    }

    func dismiss() {
        dependency.dismissAction()
    }
}
