@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class HideFilesAndFoldersViewModelTests: XCTestCase {
    
    func testHideNodes_proLevels_shouldShowOnboardingOnlyForFreeAccount() async {
        let expectations = [(validAccount: false, onboardingCalled: 1),
                            (validAccount: true, onboardingCalled: 0)]
        
        let results = await withTaskGroup(of: Bool.self) { group in
            expectations.forEach { expectation in
                group.addTask {
                    let router = MockHideFilesAndFoldersRouter()
                    let accountUseCase = MockAccountUseCase(
                        hasValidProOrUnexpiredBusinessAccount: expectation.validAccount)
                    
                    let sut = HideFilesAndFoldersViewModel(nodes: [],
                                                           router: router,
                                                           accountUseCase: accountUseCase,
                                                           nodeActionUseCase: MockNodeActionUseCase())
                    
                    await sut.hideNodes()
                    
                    return router.showHiddenFilesAndFoldersOnboardingCalled == expectation.onboardingCalled
                }
            }
            
            return await group.reduce(into: [Bool](), {
                $0.append($1)
            })
        }
        
        XCTAssertTrue(results.allSatisfy { $0 })
    }
    
    @MainActor
    func testHideNodes_nonFreeAccount_shouldHideNodesAndShowSuccessMessageWithCount() async throws {
        let router = MockHideFilesAndFoldersRouter()
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true)
        let firstSuccessNode = NodeEntity(handle: 5)
        let secondSuccessNode = NodeEntity(handle: 34)
        let failedNode = NodeEntity(handle: 76)
        let nodeActionUseCase = MockNodeActionUseCase(
            hideUnhideResult: [firstSuccessNode.handle: .success(firstSuccessNode),
                               secondSuccessNode.handle: .success(secondSuccessNode),
                               failedNode.handle: .failure(GenericErrorEntity())])
        
        let sut = makeSUT(nodes: [firstSuccessNode, secondSuccessNode, failedNode],
                          router: router,
                          accountUseCase: accountUseCase,
                          nodeActionUseCase: nodeActionUseCase)
        
        await sut.hideNodes()
        
        XCTAssertEqual(router.showItemsHiddenSuccessfullyCounts.count, 1)
        XCTAssertEqual(try XCTUnwrap(router.showItemsHiddenSuccessfullyCounts.first), 2)
    }
    
    private func makeSUT(
        nodes: [NodeEntity] = [],
        router: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        nodeActionUseCase: some NodeActionUseCaseProtocol = MockNodeActionUseCase()
    ) -> HideFilesAndFoldersViewModel {
        HideFilesAndFoldersViewModel(nodes: nodes,
                                     router: router,
                                     accountUseCase: accountUseCase,
                                     nodeActionUseCase: nodeActionUseCase)
    }
}

private class MockHideFilesAndFoldersRouter: HideFilesAndFoldersRouting {
    private(set) var nodes: [NodeEntity]?
    private(set) var showHiddenFilesAndFoldersOnboardingCalled = 0
    private(set) var showItemsHiddenSuccessfullyCounts = [Int]()
    
    func hideNodes(_ nodes: [NodeEntity]) {
        self.nodes = nodes
    }
    
    func showHiddenFilesAndFoldersOnboarding() {
        showHiddenFilesAndFoldersOnboardingCalled += 1
    }
    
    func showItemsHiddenSuccessfully(count: Int) {
        showItemsHiddenSuccessfullyCounts.append(count)
    }
}
