@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class HideFilesAndFoldersViewModelTests: XCTestCase {
    
    @MainActor
    func testHide_invalidProProOrBussinessAccount_shouldShowSeeUpgradePlansOnboarding() async {
        let router = MockHideFilesAndFoldersRouter()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: false)

        let sut = HideFilesAndFoldersViewModel(nodes: [NodeEntity(handle: 1)],
                                               router: router,
                                               sensitiveNodeUseCase: sensitiveNodeUseCase,
                                               nodeActionUseCase: MockNodeActionUseCase(),
                                               contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase())
        
        await sut.hide()
        
        XCTAssertEqual(router.showSeeUpgradePlansOnboardingCalled, 1)
    }
    
    @MainActor
    func testHide_validAccountNotOnboardedBefore_shouldShowFirstTimeOnboardingAndHandleOnboardCorrectly() async throws {
        let router = MockHideFilesAndFoldersRouter()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: true)
        let contentConsumptionUseCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))
        let node = NodeEntity(handle: 1)
        let nodeActionUseCase = MockNodeActionUseCase(
            hideUnhideResult: [node.handle: .success(node)])
        
        let sut = makeSUT(nodes: [node],
                          router: router,
                          sensitiveNodeUseCase: sensitiveNodeUseCase,
                          nodeActionUseCase: nodeActionUseCase,
                          contentConsumptionUserAttributeUseCase: contentConsumptionUseCase)
        
        await sut.hide()
        
        XCTAssertEqual(router.showShowFirstTimeOnboardingCalled, 1)
    }
    
    @MainActor
    func testHideNodes_validAccountAndUserAlreadyOnboarded_shouldHideNodesAndShowSuccessMessageWithCount() async throws {
        let router = MockHideFilesAndFoldersRouter()
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: true)
        let contentConsumptionUseCase = MockContentConsumptionUserAttributeUseCase(
            sensitiveNodesUserAttributeEntity: .init(onboarded: true, showHiddenNodes: false))
        let firstSuccessNode = NodeEntity(handle: 5)
        let secondSuccessNode = NodeEntity(handle: 34)
        let failedNode = NodeEntity(handle: 76)
        let nodeActionUseCase = MockNodeActionUseCase(
            hideUnhideResult: [firstSuccessNode.handle: .success(firstSuccessNode),
                               secondSuccessNode.handle: .success(secondSuccessNode),
                               failedNode.handle: .failure(GenericErrorEntity())])
        
        let sut = makeSUT(nodes: [firstSuccessNode, secondSuccessNode, failedNode],
                          router: router,
                          sensitiveNodeUseCase: sensitiveNodeUseCase,
                          nodeActionUseCase: nodeActionUseCase,
                          contentConsumptionUserAttributeUseCase: contentConsumptionUseCase)
        
        await sut.hide()
        
        XCTAssertEqual(router.showItemsHiddenSuccessfullyCounts.count, 1)
        XCTAssertEqual(try XCTUnwrap(router.showItemsHiddenSuccessfullyCounts.first), 2)
    }
    
    @MainActor
    private func makeSUT(
        nodes: [NodeEntity] = [],
        router: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        nodeActionUseCase: some NodeActionUseCaseProtocol = MockNodeActionUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase()
    ) -> HideFilesAndFoldersViewModel {
        HideFilesAndFoldersViewModel(
            nodes: nodes,
            router: router,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeActionUseCase: nodeActionUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase)
    }
}
