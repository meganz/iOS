@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
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
        let sut = makeSUT(
            nodes: nodes,
            contentConsumptionUserAttributeUseCase: contentConsumptionUseCase,
            hideFilesAndFoldersRouter: router
        )
        
        await sut.buttonAction()
        
        let updatedSensitiveAttributes = await contentConsumptionUseCase.fetchSensitiveAttribute()
        XCTAssertTrue(updatedSensitiveAttributes.onboarded)
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(try XCTUnwrap(router.nodes), nodes)
    }
    
    private func makeSUT(
        nodes: [NodeEntity] = [],
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        hideFilesAndFoldersRouter: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FirstTimeOnboardingPrimaryButtonViewModel {
        FirstTimeOnboardingPrimaryButtonViewModel(
            nodes: nodes,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hideFilesAndFoldersRouter: hideFilesAndFoldersRouter)
    }
}
