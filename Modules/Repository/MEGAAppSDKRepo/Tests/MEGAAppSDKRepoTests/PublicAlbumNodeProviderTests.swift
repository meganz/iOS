@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class PublicAlbumNodeProviderTests: XCTestCase {
    func testNodeForHandle_forNodeNotFound_shouldReturnNil() async {
        let sut = makePublicAlbumNodeProvider()
        let node = await sut.node(for: 5)
        XCTAssertNil(node)
    }
    
    func testNodeForHandle_nodeNotCached_shouldRetrieveAndCache() async {
        let handle = HandleEntity(35)
        let setElementInPreview = MockMEGASetElement(handle: 1, nodeId: handle)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode], megaSetElements: [setElementInPreview])
        let sut = makePublicAlbumNodeProvider(sdk: sdk)
        
        let node = await sut.node(for: handle)
        let cachedNode = await sut.node(for: handle)
        
        XCTAssertEqual(node, expectedNode)
        XCTAssertEqual(node, cachedNode)
    }
    
    func testNodeForHandle_simultaneousRetrieval_shouldReturnSameValue() async {
        let handle = HandleEntity(56)
        let setElementInPreview = MockMEGASetElement(handle: 1, nodeId: handle)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode], megaSetElements: [setElementInPreview])
        let sut = makePublicAlbumNodeProvider(sdk: sdk)
        
        async let call1 = sut.node(for: handle)
        async let call2 = sut.node(for: handle)
        
        let (result1, result2) = await (call1, call2)
        XCTAssertEqual(result1, expectedNode)
        XCTAssertEqual(result2, expectedNode)
    }
    
    func testNodeForHandle_forNodeNotCachedElementsDontContainNode_shouldReturnNil() async {
        let handle = HandleEntity(35)
        
        let sdk = MockSdk(megaSetElements: [])
        let sut = makePublicAlbumNodeProvider(sdk: sdk)
        
        let node = await sut.node(for: handle)
        
        XCTAssertNil(node)
    }
    
    func testPublicPhotoNode_onNodeNotCached_shouldRetrieveNodeAndCacheIt() async throws {
        let handle = HandleEntity(25)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode])
        let photoElement = SetElementEntity(handle: 1, nodeId: handle)
        let sut = makePublicAlbumNodeProvider(sdk: sdk)
        
        let node = try await sut.publicPhotoNode(for: photoElement)
        let cachedNode = try await sut.publicPhotoNode(for: photoElement)
        XCTAssertEqual(node, expectedNode)
        XCTAssertEqual(node, cachedNode)
    }
    
    func testPublicPhotoNode_onNodeNotCachedSDKNotOkKnownError_shouldThrowCorrectError() async {
        let testCase = [(MEGAErrorType.apiEArgs, SharedPhotoErrorEntity.photoNotFound),
                        (.apiEAccess, .previewModeNotEnabled)
        ]
        
        let result = await withTaskGroup(of: Bool.self) { group in
            testCase.forEach { testCase in
                group.addTask {
                    let mockSdk = MockSdk(megaSetError: testCase.0)
                    let sut = PublicAlbumNodeProvider(sdk: mockSdk)
                    do {
                        _ = try await sut.publicPhotoNode(for: SetElementEntity(handle: 1, nodeId: 5))
                        return false
                    } catch {
                        return error as? SharedPhotoErrorEntity == testCase.1
                    }
                }
            }
            
            return await group.allSatisfy { $0 }
        }
        XCTAssertTrue(result)
    }
    
    func testPublicPhotoNode_onNodeNotCachedUnknownError_shouldThrowGenericError() async throws {
        let handle = HandleEntity(25)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode], megaSetError: .apiEFailed)
        
        let sut = makePublicAlbumNodeProvider(sdk: sdk)
        
        do {
            _ = try await sut.publicPhotoNode(for: SetElementEntity(handle: 1, nodeId: handle))
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    // MARK: - Private
    private func makePublicAlbumNodeProvider(sdk: MEGASdk = MockSdk()) -> PublicAlbumNodeProvider {
        PublicAlbumNodeProvider(sdk: sdk)
    }
}
