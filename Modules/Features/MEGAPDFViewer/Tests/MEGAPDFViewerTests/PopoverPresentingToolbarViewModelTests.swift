@testable import MEGAPDFViewer
import Testing

@MainActor
struct PopoverPresentingToolbarViewModelTests {
    @Test
    func unavailableAction_doesNotHideLeadingSideItems() {
        let sut = PopoverPresentingToolbarViewModel(onTapped: nil)

        sut.didTap(isPopoverMorphExpected: true)

        #expect(!sut.shouldHideLeadingSideItems)
    }

    @Test
    func morph_hidesLeadingSideItemsBeforeCallingPresenter() {
        var hiddenWhenCalled: Bool?
        var sut: PopoverPresentingToolbarViewModel?
        sut = PopoverPresentingToolbarViewModel(onTapped: { _ in
            hiddenWhenCalled = sut?.shouldHideLeadingSideItems
        })

        sut?.didTap(isPopoverMorphExpected: true)

        #expect(hiddenWhenCalled == true)
    }

    @Test
    func morph_keepsLeadingSideItemsHiddenUntilPresentedOrSkippedCompletion() {
        var completion: (@MainActor () -> Void)?
        let sut = PopoverPresentingToolbarViewModel(onTapped: { completion = $0 })

        sut.didTap(isPopoverMorphExpected: true)

        #expect(sut.shouldHideLeadingSideItems)
        #expect(completion != nil)
        completion?()
        #expect(!sut.shouldHideLeadingSideItems)
    }

    @Test
    func sheet_doesNotHideLeadingSideItemsOrRequestMorphCompletion() {
        var callCount = 0
        var completion: (@MainActor () -> Void)?
        let sut = PopoverPresentingToolbarViewModel(onTapped: {
            callCount += 1
            completion = $0
        })

        sut.didTap(isPopoverMorphExpected: false)

        #expect(callCount == 1)
        #expect(completion == nil)
        #expect(!sut.shouldHideLeadingSideItems)
    }
}

@MainActor
struct PopoverPresentingToolbarPolicyTests {
    @Test(arguments: [false, true])
    func activity_onLiquidGlassIPad_morphsInEitherWindowMode(isFullScreen: Bool) {
        let policy = PopoverPresentingToolbarContent.PresentationPolicy.activity

        #expect(policy.shouldMorph(
            isIPad: true, isLiquidGlass: true,
            isInFullScreenWindow: isFullScreen
        ))
    }

    @Test(arguments: [false, true])
    func moreMenu_onLiquidGlassIPad_morphsOnlyInFullScreen(isFullScreen: Bool) {
        let policy = PopoverPresentingToolbarContent.PresentationPolicy.moreMenu

        #expect(policy.shouldMorph(
            isIPad: true, isLiquidGlass: true,
            isInFullScreenWindow: isFullScreen
        ) == isFullScreen)
    }

    @Test(arguments: [false, true])
    func iPhone_doesNotRequestPopoverMorph(isLiquidGlass: Bool) {
        let policy = PopoverPresentingToolbarContent.PresentationPolicy.activity

        #expect(!policy.shouldMorph(
            isIPad: false, isLiquidGlass: isLiquidGlass,
            isInFullScreenWindow: true
        ))
    }

    @Test(arguments: [false, true])
    func earlierIPad_keepsPopoverAnchorWithoutRequestingMorph(isFullScreen: Bool) {
        let policy = PopoverPresentingToolbarContent.PresentationPolicy.activity

        #expect(!policy.shouldMorph(
            isIPad: true, isLiquidGlass: false,
            isInFullScreenWindow: isFullScreen
        ))
    }
}
