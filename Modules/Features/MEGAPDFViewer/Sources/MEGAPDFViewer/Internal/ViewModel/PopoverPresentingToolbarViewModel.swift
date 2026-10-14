import Observation

@MainActor
@Observable
final class PopoverPresentingToolbarViewModel {
    private(set) var shouldHideLeadingSideItems = false
    @ObservationIgnored private let onTapped: (@MainActor ((@MainActor () -> Void)?) -> Void)?

    init(onTapped: (@MainActor ((@MainActor () -> Void)?) -> Void)?) {
        self.onTapped = onTapped
    }

    func didTap(isPopoverMorphExpected: Bool) {
        guard let onTapped else { return }
        guard isPopoverMorphExpected else { return onTapped(nil) }

        // The morph removes the source bar item temporarily, so hiding items
        // on its leading side prevents the toolbar shifting its position.
        shouldHideLeadingSideItems = true
        onTapped { [weak self] in
            self?.shouldHideLeadingSideItems = false
        }
    }
}
