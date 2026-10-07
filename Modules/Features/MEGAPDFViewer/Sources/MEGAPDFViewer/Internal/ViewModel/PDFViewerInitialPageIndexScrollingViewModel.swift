import Combine
import CoreGraphics

@MainActor
final class PDFViewerInitialPageIndexScrollingViewModel {
    struct ContentInsetState: Equatable {
        let scrollViewAdjustedContentInsetTop: CGFloat
        let pdfViewSafeAreaInsetTop: CGFloat
    }

    /// Published at most once, after the initial scroll to top and once the
    /// content scroll view's insets have settled.
    @Published private(set) var initialPageNavigationRequest: Int?

    var initialPageIndex: Int?

    var contentInsetState: ContentInsetState? {
        didSet {
            updateContentScrollViewInsetsDidSettle()
        }
    }

    @Published private var contentScrollViewInsetsDidSettle = false
    private var hasObservedInitialScrollToTop = false
    private var lastScrollViewAdjustedContentInsetTop: CGFloat?
    private var subscriptions = Set<AnyCancellable>()

    func startObservingScrollToTop(
        didTriggerInitialScrollToTop: some Publisher<Bool, Never>
    ) {
        didTriggerInitialScrollToTop
            .filter { $0 }
            .sink { [weak self] _ in self?.hasObservedInitialScrollToTop = true }
            .store(in: &subscriptions)

        didTriggerInitialScrollToTop
            .combineLatest($contentScrollViewInsetsDidSettle)
            .filter { $0 && $1 }
            .prefix(1)
            .sink { [weak self] _ in
                guard let self, let initialPageIndex else { return }
                initialPageNavigationRequest = initialPageIndex
            }
            .store(in: &subscriptions)
    }

    private func updateContentScrollViewInsetsDidSettle() {
        guard !contentScrollViewInsetsDidSettle, let contentInsetState else { return }
        // - Measured on iOS 18.6: the content scroll view takes its inset from
        //   the safe area one layout pass after the initial fit, then shifts
        //   the offset by that inset, which would move a page navigated to
        //   before then off centre. iOS 26.5 already has the inset on the
        //   first pass.
        // - An inset unchanged across two layout passes also counts, once the
        //   initial scroll to top has fired, so a setup where the inset never
        //   matches the safe area still restores. Before the fit, an
        //   unchanged inset can still be pending, as on iOS 18.6.
        let insetTop = contentInsetState.scrollViewAdjustedContentInsetTop
        let matchesSafeArea = abs(insetTop - contentInsetState.pdfViewSafeAreaInsetTop) < 0.5
        let isUnchangedSinceLastPass = hasObservedInitialScrollToTop
            && lastScrollViewAdjustedContentInsetTop.map { abs($0 - insetTop) < 0.5 } == true
        lastScrollViewAdjustedContentInsetTop = insetTop
        contentScrollViewInsetsDidSettle = matchesSafeArea || isUnchangedSinceLastPass
    }
}
