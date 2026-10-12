@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewerMoreButtonViewModelTests {
    @Test
    func showsMoreButton_withOnMoreTapped_isTrue() {
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: { _ in })

        #expect(sut.showsMoreButton(isDocumentLoadFailed: false))
    }

    @Test
    func showsMoreButton_withOnMoreTapped_isFalseWhenDocumentLoadFailed() {
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: { _ in })

        #expect(!sut.showsMoreButton(isDocumentLoadFailed: true))
    }

    @Test
    func showsMoreButton_withoutOnMoreTapped_isFalse() {
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: nil)

        #expect(!sut.showsMoreButton(isDocumentLoadFailed: false))
    }

    @Test
    func didTapMore_invokesOnMoreTappedOnceWithoutCompletion() {
        var completions: [PDFViewerMoreMenuDependencies.OnMoreAnimationCompletion?] = []
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: { completions.append($0) })

        sut.didTapMore()

        #expect(completions.count == 1)
        #expect(completions.first.flatMap { $0 } == nil)
        #expect(!sut.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation)
    }

    @Test
    func didTapMoreBarItem_inFullScreenWindow_hidesTransferIndicatorBeforeInvokingOnMoreTapped() {
        var isHiddenWhenInvoked: Bool?
        var sut: PDFViewerMoreButtonViewModel?
        sut = PDFViewerMoreButtonViewModel(onMoreTapped: { _ in
            isHiddenWhenInvoked = sut?.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation
        })

        sut?.didTapMoreBarItem(isInFullScreenWindow: true)

        #expect(isHiddenWhenInvoked == true)
    }

    @Test
    func didTapMoreBarItem_inFullScreenWindow_keepsTransferIndicatorHiddenUntilCompletion() {
        var completion: PDFViewerMoreMenuDependencies.OnMoreAnimationCompletion?
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: { completion = $0 })

        sut.didTapMoreBarItem(isInFullScreenWindow: true)

        #expect(sut.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation)

        completion?()

        #expect(!sut.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation)
    }

    @Test
    func didTapMoreBarItem_inFullScreenWindow_withoutOnMoreTapped_keepsTransferIndicatorShown() {
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: nil)

        sut.didTapMoreBarItem(isInFullScreenWindow: true)

        #expect(!sut.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation)
    }

    @Test
    func didTapMoreBarItem_outsideFullScreenWindow_forwardsWithoutHidingTransferIndicator() {
        var completions: [PDFViewerMoreMenuDependencies.OnMoreAnimationCompletion?] = []
        let sut = PDFViewerMoreButtonViewModel(onMoreTapped: { completions.append($0) })

        sut.didTapMoreBarItem(isInFullScreenWindow: false)

        #expect(completions.count == 1)
        #expect(completions.first.flatMap { $0 } == nil)
        #expect(!sut.isTransferIndicatorHiddenForiPadLiquidGlassMorePopoverAnimation)
    }
}
