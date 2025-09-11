@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

struct ImportLinkViewModelTests {

    @MainActor
    @Test
    func importEmptyNodesDoNothing() {
        let router = MockImportLinkRouter()
        let sut = Self.makeSUT(
            router: router,
            isFolderLink: false,
            nodes: [])
        
        sut.importNodes()
        
        #expect(router.showNodeBrowserCalled == 0)
        #expect(router.showOnboardingCalled == 0)
    }
    
    @MainActor
    @Test(arguments: [true, false])
    func loggedInShowNodeBrowser(isFolderLink: Bool) {
        let router = MockImportLinkRouter()
        let sut = Self.makeSUT(
            router: router,
            credentialUseCase: MockCredentialUseCase(
                session: true
            ),
            isFolderLink: isFolderLink,
            nodes: [MockNode(handle: 1)])
        
        sut.importNodes()
        
        #expect(router.showNodeBrowserCalled == 1)
    }
    
    @MainActor
    @Test("Show onboarding when logged out and set link manager options correctly",
          arguments: [true, false])
    func loggedOutShowOnboarding(isFolderLink: Bool) {
        let router = MockImportLinkRouter()
        let sut = Self.makeSUT(
            router: router,
            credentialUseCase: MockCredentialUseCase(
                session: false
            ),
            isFolderLink: isFolderLink,
            nodes: [MockNode(handle: 1)])
        
        sut.importNodes()
        
        #expect(MEGALinkManager.selectedOption == (isFolderLink ? .importFolderOrNodes : .importNode))
        #expect(router.showOnboardingCalled == 1)
        
    }

    @MainActor
    private static func makeSUT(
        router: some ImportLinkRouting = MockImportLinkRouter(),
        credentialUseCase: some CredentialUseCaseProtocol = MockCredentialUseCase(),
        isFolderLink: Bool,
        nodes: [MEGANode]
    ) -> ImportLinkViewModel {
        .init(
            router: router,
            credentialUseCase: credentialUseCase,
            isFolderLink: isFolderLink,
            nodes: nodes)
    }
}
