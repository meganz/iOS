@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class FirstTimeOnboardingPrimaryButtonViewModelTests: XCTestCase {

    func testButtonTitle_init_isCorrect() throws {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.buttonTitle, Strings.Localizable.continue)
    }
    
    @MainActor
    func testHide_validAccountNotOnboardedBefore_shouldShowFirstTimeOnboardingAndHandleOnboardCorrectly() async throws {
        let nodes = [NodeEntity(handle: 1)]
        let contentConsumptionUseCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))
        let router = MockHideFilesAndFoldersRouter()
        let tracker = MockTracker()
        let sut = makeSUT(
            nodes: nodes,
            contentConsumptionUserAttributeUseCase: contentConsumptionUseCase,
            hideFilesAndFoldersRouter: router,
            tracker: tracker
        )
        
        await sut.buttonAction()
        
        let updatedSensitiveAttributes = await contentConsumptionUseCase.fetchSensitiveAttribute()
        XCTAssertTrue(updatedSensitiveAttributes.onboarded)
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(try XCTUnwrap(router.nodes), nodes)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [HiddenNodeOnboardingContinueButtonPressedEvent()]
        )
    }
    
    private func makeSUT(
        nodes: [NodeEntity] = [],
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> FirstTimeOnboardingPrimaryButtonViewModel {
        FirstTimeOnboardingPrimaryButtonViewModel(
            nodes: nodes,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter,
            tracker: tracker)
    }
}
