@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@Suite("HideFilesAndFoldersViewModel Tests")
struct HideFilesAndFoldersViewModelTests {
    
    @Suite("Hide")
    @MainActor
    struct Hide {
        @Test("when invalid pro or business it should show see upgrade plans onboarding")
        func invalidProProOrBusinessAccount() async {
            let router = MockHideFilesAndFoldersRouter()
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: false)
            
            let sut = HideFilesAndFoldersViewModel(
                nodes: [NodeEntity(handle: 1)],
                router: router,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeActionUseCase: MockNodeActionUseCase(),
                contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase())
            
            await sut.hide()
            
            #expect(router.showSeeUpgradePlansOnboardingCalled == 1)
        }
        
        @Test("when valid account not onboarded before should show first time onboarding")
        func validAccountNotOnboardedBefore() async {
            let router = MockHideFilesAndFoldersRouter()
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: true)
            let contentConsumptionUseCase = MockContentConsumptionUserAttributeUseCase(
                sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))
            let node = NodeEntity(handle: 1)
            let nodeActionUseCase = MockNodeActionUseCase(
                hideUnhideResult: [node.handle: .success(node)])
            
            let sut = makeSUT(
                nodes: [node],
                router: router,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeActionUseCase: nodeActionUseCase,
                contentConsumptionUserAttributeUseCase: contentConsumptionUseCase)
            
            await sut.hide()
            
            #expect(router.showShowFirstTimeOnboardingCalled == 1)
        }
        
        @Test("when valid account and already onboarded it should hide nodes and show toast message")
        func validAccountAndUserAlreadyOnboarded() async {
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
            
            let sut = makeSUT(
                nodes: [firstSuccessNode, secondSuccessNode, failedNode],
                router: router,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeActionUseCase: nodeActionUseCase,
                contentConsumptionUserAttributeUseCase: contentConsumptionUseCase)
            
            await sut.hide()
            
            #expect(router.showSnackBarMessages == [Strings.Localizable.Nodes.Action.hideItems(2)])
        }
    }
    
    @Suite("Unhide")
    @MainActor
    struct Unhide {
        @Test("when nodes are successfully unhidden then show snack bar message")
        func unhideSuccessfully() async {
            let router = MockHideFilesAndFoldersRouter()
            let successNode = NodeEntity(handle: 5)
            let failedNode = NodeEntity(handle: 76)
            let nodeActionUseCase = MockNodeActionUseCase(
                hideUnhideResult: [successNode.handle: .success(successNode),
                                   failedNode.handle: .failure(GenericErrorEntity())])
            
            let sut = makeSUT(
                nodes: [successNode, failedNode],
                router: router,
                nodeActionUseCase: nodeActionUseCase)
            
            await sut.unhide()
            
            #expect(router.showSnackBarMessages == [Strings.Localizable.Nodes.Action.unhideItems(1)])
        }
    }
    
    @MainActor
    private static func makeSUT(
        nodes: [NodeEntity] = [],
        router: some HideFilesAndFoldersRouting = MockHideFilesAndFoldersRouter(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        nodeActionUseCase: some NodeActionUseCaseProtocol = MockNodeActionUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase()
    ) -> HideFilesAndFoldersViewModel {
        .init(
            nodes: nodes,
            router: router,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeActionUseCase: nodeActionUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase)
    }
}
