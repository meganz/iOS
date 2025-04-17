@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class BrowserViewModelTests: XCTestCase {
    
    func testNodesForParent_parentNodeProvided_shouldReturn() async {
        let parentNode = MockNode(handle: 5)
        let expectedNodes = [MockNode(handle: 65), MockNode(handle: 654)]
        let sdk = MockSdk(nodes: expectedNodes)
        let sut = makeSUT(
            parentNode: parentNode,
            sdk: sdk)
        
        let nodes = await sut.nodesForParent()
        
        XCTAssertEqual(nodes.toNodeEntities(), expectedNodes.toNodeEntities())
        XCTAssertEqual(sdk.searchQueryParameters?.node, parentNode)
    }
    
    func testNodesForParent_parentNodeNotProvidedIsNotChildBrowser_shouldReturnNodesFromRootNode() async {
        let rootNode = MockNode(handle: 5)
        let expectedNodes = [MockNode(handle: 65), MockNode(handle: 654)]
        let sdk = MockSdk(nodes: expectedNodes, megaRootNode: rootNode)
        let sut = makeSUT(
            parentNode: nil,
            sdk: sdk)
        
        let nodes = await sut.nodesForParent()
        
        XCTAssertEqual(nodes.toNodeEntities(), expectedNodes.toNodeEntities())
        XCTAssertEqual(sdk.searchQueryParameters?.node, rootNode)
    }
    
    func testNodesForParent_parentNotProvidedAndChildBrowser_shouldReturnEmpty() async {
        let sut = makeSUT(
            parentNode: nil)
        
        let nodes = await sut.nodesForParent()
        
        XCTAssertTrue(nodes.toNodeArray().isEmpty)
    }
    
    func testNodesForParent_isSelectVideosForParent_shouldReturnFoldersAndVideosOnly() async {
        let parentNode = MockNode(handle: 5, nodeType: .file)
        let allNodes = [MockNode(handle: 65, nodeType: .folder),
                        MockNode(handle: 654, name: "video.mp4"),
                        MockNode(handle: 654, name: "test.mov")]
        let sdk = MockSdk(nodes: allNodes)
        let sut = makeSUT(
            parentNode: parentNode,
            sdk: sdk)
        
        let nodes = await sut.nodesForParent()
        
        let expectedNodes = allNodes.filter { $0.isFile() || $0.isFolder() }
        XCTAssertEqual(nodes.toNodeEntities(), expectedNodes.toNodeEntities())
        XCTAssertEqual(sdk.searchQueryParameters?.node, parentNode)
    }
    
    func testNodesForParent_showHiddenNodesLoaded_shouldUseCorrectSensitivityFilter() async {
        for exludeSensitives in [true, false] {
            let allNodes = [MockNode(handle: 65),
                            MockNode(handle: 654)]
            let sdk = MockSdk(nodes: allNodes)
            let sut = makeSUT(
                parentNode: MockNode(handle: 5),
                sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(
                    excludeSensitives: exludeSensitives),
                sdk: sdk)
            
            let nodes = await sut.nodesForParent()
            
            XCTAssertEqual(nodes.toNodeEntities(), allNodes.toNodeEntities())
            XCTAssertEqual(sdk.searchQueryParameters?.sensitiveFilter, exludeSensitives ? .nonSensitiveOnly : .disabled)
        }
    }
    
    func testUpdateParentNode_nodesForParentCalled_shouldUseCorrectHandleForSearch() async {
        let sdk = MockSdk(nodes: [])
        let sut = makeSUT(
            sdk: sdk)
        
        let newParentNode = MockNode(handle: 99)
        
        sut.updateParentNode(newParentNode)
        
        _ = await sut.nodesForParent()
        
        XCTAssertEqual(sdk.searchQueryParameters?.node, newParentNode)
    }
    
    func makeSUT(
        parentNode: MEGANode? = nil,
        isChildBrowser: Bool = false,
        isSelectVideos: Bool = false,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        filesSearchUseCase: some FilesSearchUseCaseProtocol = MockFilesSearchUseCase(),
        metadataUseCase: some MetadataUseCaseProtocol = MockMetadataUseCase(),
        sdk: MEGASdk = MockSdk(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BrowserViewModel {
        let sut = BrowserViewModel(
            parentNode: parentNode,
            isChildBrowser: isChildBrowser,
            isSelectVideos: isSelectVideos,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            filesSearchUseCase: filesSearchUseCase,
            metadataUseCase: metadataUseCase,
            sdk: sdk)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
