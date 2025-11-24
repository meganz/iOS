@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import Testing

struct HiddenFilesFoldersOnboardingViewModelTests {
    @MainActor
    @Test
    func onViewAppear_called_shouldTrackTheCorrectEvent() {
        let screenEvents: [any ScreenViewEventIdentifier] = [
            HideNodeOnboardingScreenEvent(),
            HideNodeUpgradeScreenEvent()]
        
        for screenEvent in screenEvents {
            let tracker = MockTracker()
            let sut = Self.makeSUT(
                tracker: tracker,
                screenEvent: screenEvent)
            
            sut.onViewAppear()
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [screenEvent]
            )
        }
    }
    
    @MainActor
    @Test
    func onDismissButtonTapped_called_shouldTrackTheCorrectEvent() {
        let dismissEvent = HiddenNodeOnboardingCloseButtonPressedEvent()
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            tracker: tracker,
            dismissEvent: dismissEvent)
        
        sut.onDismissButtonTapped()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [dismissEvent]
        )
    }
    
    @MainActor
    @Test
    func viewConfiguration_init_shouldShowCorrectValues() {
        let showPrimaryButtonOnly = true
        let showNavigationBar = false
        
        let sut = Self.makeSUT(
            showPrimaryButtonOnly: showPrimaryButtonOnly,
            showNavigationBar: showNavigationBar)
        
        #expect(sut.showPrimaryButtonOnly == showPrimaryButtonOnly)
        #expect(sut.showNavigationBar == showNavigationBar)
    }
    
    @MainActor
    @Test
    func descriptionItems_shouldReturnCorrectLocalizedStrings() {
        let sut = Self.makeSUT()
        
        let items = sut.descriptionItems
        
        let firstItem = items[safe: 0]
        #expect(firstItem?.title == Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.One.title)
        #expect(firstItem?.description == Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.One.message)
        
        let secondItem = items[safe: 1]
        #expect(secondItem?.title == Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.Two.title)
        let originalMessage = Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.ControlVisibility.message
        #expect(secondItem?.description == originalMessage.replacing("[A]", with: "").replacing("[/A]", with: ""))
        
        let thirdItem = items[safe: 2]
        #expect(thirdItem?.title == Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.Three.title)
        #expect(thirdItem?.description == Strings.Localizable.Onboarding.HiddenFilesAndFolders.Content.Item.Three.message)
    }
    
    @MainActor
    @Test
    func descriptionItems_secondItemHighlightedTextAction_whenAccessible_shouldCallRouter() {
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: true)
        let router = MockHideFilesAndFoldersRouter()
        
        let sut = Self.makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            hideFilesAndFoldersRouter: router)
        
        let items = sut.descriptionItems
        let secondItem = items[1]
        
        secondItem.descriptionHighlightedText?.action?()
        
        #expect(router.showUserInterfaceSettingsCalled == 1)
    }

    @MainActor
    private static func makeSUT(
        showPrimaryButtonOnly: Bool = false,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        showNavigationBar: Bool = true,
        tracker: some AnalyticsTracking = MockTracker(),
        screenEvent: (any ScreenViewEventIdentifier)? = nil,
        dismissEvent: (any ButtonPressedEventIdentifier)? = nil
    ) -> HiddenFilesFoldersOnboardingViewModel {
        HiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: showPrimaryButtonOnly,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            showNavigationBar: showNavigationBar,
            tracker: tracker,
            screenEvent: screenEvent,
            dismissEvent: dismissEvent)
    }
}
