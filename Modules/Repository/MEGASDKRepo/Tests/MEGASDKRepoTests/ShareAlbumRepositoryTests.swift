import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

class ShareAlbumRepositoryTests: XCTestCase {
    func testShareAlbumLink_onAlbumThatsNotShared_shouldReturnSharedLink() async throws {
        let expectedLink = "the_shared_link"
        let mockSdk = MockSdk(link: expectedLink)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        let result = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false)))
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareAlbumLink_onAlbumThatsShared_shouldReturnExistingSharedLink() async throws {
        let expectedLink = "the_existing_shared_link"
        let mockSdk = MockSdk(link: expectedLink)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        let result = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true)))
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareAlbum_onBuisinessPastDue_shouldThrowError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBusinessPastDue)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false)))
        } catch {
            XCTAssertEqual(error as? ShareCollectionErrorEntity, ShareCollectionErrorEntity.buisinessPastDue)
        }
    }
    
    func testShareAlbum_onOtherError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false)))
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testDisableAlbumShare_onSuccess_shouldComplete() async throws {
        let sut = makeShareAlbumRepository(sdk: MockSdk())
        try await sut.removeSharedLink(forAlbumId: 1)
    }
    
    func testDisableAlbumShare_onBuisinessPastDue_shouldThrowError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBusinessPastDue)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        do {
            try await sut.removeSharedLink(forAlbumId: 1)
        } catch {
            XCTAssertEqual(error as? ShareCollectionErrorEntity, ShareCollectionErrorEntity.buisinessPastDue)
        }
    }
    
    func testDisableAlbumShare_onOtherError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        do {
            try await sut.removeSharedLink(forAlbumId: 1)
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testPublicAlbumContents_onSuccessfulResponse_shouldReturnSharedAlbumEntity() async throws {
        let expectedSet = MockMEGASet(handle: 54)
        let expectedSetElements = [MockMEGASetElement(handle: 43),
                                   MockMEGASetElement(handle: 89)]
        let sdk = MockSdk(megaSets: [expectedSet], megaSetElements: expectedSetElements)
        let sut = makeShareAlbumRepository(sdk: sdk)
        let result = try await sut.publicAlbumContents(forLink: "public_link")
        XCTAssertEqual(result.set, expectedSet.toSetEntity())
        XCTAssertEqual(result.setElements, expectedSetElements.toSetElementsEntities())
        XCTAssertEqual(sdk.stopPublicSetPreviewCalled, 1)
    }
    
    func testPublicAlbumContents_onSDKNotOkKnownError_shouldThrowCorrectError() async {
        let testCase = [(MEGAErrorType.apiENoent, SharedCollectionErrorEntity.resourceNotFound),
                        (.apiEInternal, .couldNotBeReadOrDecrypted),
                        (.apiEArgs, .malformed),
                        (.apiEAccess, .permissionError)
        ]
        
        let result = await withTaskGroup(of: Bool.self) { group in
            testCase.forEach { testCase in
                group.addTask {
                    let mockSdk = MockSdk(megaSetError: testCase.0)
                    let sut = ShareAlbumRepository(sdk: mockSdk,
                                                   publicAlbumNodeProvider: MockPublicAlbumNodeProvider())
                    do {
                        _ = try await sut.publicAlbumContents(forLink: "public_link")
                        return false
                    } catch {
                        return error as? SharedCollectionErrorEntity == testCase.1
                    }
                }
            }
            
            return await group.allSatisfy { $0 }
        }
        XCTAssertTrue(result)
    }
    
    func testPublicAlbumContents_onSDKNotOkUnknownError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = makeShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.publicAlbumContents(forLink: "public_link")
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testPublicAlbumContents_onContentsRetrieval_shouldClearCacheThenReturnSharedAlbum() async throws {
        let provider = MockPublicAlbumNodeProvider()
        let expectedSet = MockMEGASet(handle: 54)
        let sdk = MockSdk(megaSets: [expectedSet])
        
        let sut = makeShareAlbumRepository(sdk: sdk, publicAlbumNodeProvider: provider)
        let result = try await sut.publicAlbumContents(forLink: "public_link")
        XCTAssertEqual(result.set, expectedSet.toSetEntity())
        XCTAssertTrue(result.setElements.isEmpty)
        
        XCTAssertEqual(provider.clearCacheCalled, 1)
    }
    
    func testStopAlbumLinkPreview_called_shouldCallSDKToStopPublicSetPreview() {
        let sdk = MockSdk()
        let sut = makeShareAlbumRepository(sdk: sdk)
        
        sut.stopAlbumLinkPreview()
        
        XCTAssertEqual(sdk.stopPublicSetPreviewCalled, 1)
    }
    
    func testPublicPhoto_onProviderReturnsPhotos_shouldConvertAndReturn() async throws {
        let handle = HandleEntity(7)
        let expectedNode = MockNode(handle: handle)
        let provider = MockPublicAlbumNodeProvider(nodes: [expectedNode])
        let sut = makeShareAlbumRepository(publicAlbumNodeProvider: provider)
        
        let result = try await sut.publicPhoto(SetElementEntity(handle: 6, nodeId: handle))
        
        XCTAssertEqual(result, expectedNode.toNodeEntity())
    }
    
    func testCopyPublicPhotos_noPhotos_shouldReturnEmpty() async throws {
        let sut = makeShareAlbumRepository()
        
        let copiedPhotos = try await sut.copyPublicPhotos(toFolder: NodeEntity(handle: 1),
                                                          photos: [])
        XCTAssertTrue(copiedPhotos.isEmpty)
    }
    
    func testCopyPublicPhotos_folderNotFound_shouldThrowNodeNotFound() async {
        let sut = makeShareAlbumRepository()
        
        do {
            _ = try await sut.copyPublicPhotos(toFolder: NodeEntity(handle: 1),
                                               photos: [NodeEntity(handle: 1)])
            XCTFail("Should have thrown nodeNotFound")
        } catch {
            XCTAssertEqual(error as? NodeErrorEntity, NodeErrorEntity.nodeNotFound)
        }
    }
    
    func testCopyPublicPhotos_validFolderWithPublicPhotos_shouldCopyAndReturnCopiedNodes() async throws {
        let folder = MockNode(handle: 8)
        let photoHandles: [HandleEntity] = [23, 55, 76]
        let publicPhotos = photoHandles.map { MockNode(handle: $0) }
        let provider = MockPublicAlbumNodeProvider(nodes: publicPhotos)
        let copiedNodeHandles = Array(repeating: UInt64.random(), count: photoHandles.count)
        let copiedNodes = copiedNodeHandles.map { MockNode(handle: $0) }
        let sdk = MockSdk(nodes: [folder] + copiedNodes,
                          copiedNodeHandles: Dictionary(
                            uniqueKeysWithValues: zip(photoHandles, copiedNodeHandles)))
        let sut = makeShareAlbumRepository(sdk: sdk,
                                           publicAlbumNodeProvider: provider)
        
        let copiedPhotos = try await sut.copyPublicPhotos(toFolder: folder.toNodeEntity(),
                                                          photos: publicPhotos.toNodeEntities())
        
        XCTAssertEqual(Set(copiedPhotos), Set(copiedNodes.toNodeEntities()))
    }
    
    func testCopyPublicPhotos_publicPhotosNotRetrieved_shouldReturnEmpty() async throws {
        let folder = MockNode(handle: 8)
        let sdk = MockSdk(nodes: [folder])
        let sut = makeShareAlbumRepository(sdk: sdk)
        
        let copiedPhotos = try await sut.copyPublicPhotos(toFolder: folder.toNodeEntity(),
                                                          photos: [NodeEntity(handle: 3)])
        
        XCTAssertTrue(copiedPhotos.isEmpty)
    }
    
    func testCopyPublicPhotos_publicPhotosRetrievedCopyNotFound_shouldThrowNodeNotFound() async {
        let folder = MockNode(handle: 8)
        let publicPhotos = [MockNode(handle: 65)]
        let provider = MockPublicAlbumNodeProvider(nodes: publicPhotos)
        let sdk = MockSdk(nodes: [folder])
        let sut = makeShareAlbumRepository(sdk: sdk,
                                           publicAlbumNodeProvider: provider)
        
        do {
            _ = try await sut.copyPublicPhotos(toFolder: folder.toNodeEntity(),
                                               photos: publicPhotos.toNodeEntities())
            XCTFail("Should have thrown nodeNotFound")
        } catch {
            XCTAssertEqual(error as? NodeErrorEntity, NodeErrorEntity.nodeNotFound)
        }
    }
    
    func testCopyPublicPhotos_onSdkCopyFailed_shouldThrowCopyNodeFailed() async {
        let folder = MockNode(handle: 8)
        let publicPhotos = [MockNode(handle: 67)]
        let provider = MockPublicAlbumNodeProvider(nodes: publicPhotos)
        let sdk = MockSdk(nodes: [folder], megaSetError: .apiEArgs)
        let sut = makeShareAlbumRepository(sdk: sdk,
                                           publicAlbumNodeProvider: provider)
        
        do {
            _ = try await sut.copyPublicPhotos(toFolder: folder.toNodeEntity(),
                                               photos: publicPhotos.toNodeEntities())
            XCTFail("Should have thrown nodeCopyFailed")
        } catch {
            XCTAssertEqual(error as? CopyOrMoveErrorEntity, CopyOrMoveErrorEntity.nodeCopyFailed)
        }
    }
    
    // MARK: - Private
    private func makeShareAlbumRepository(sdk: MEGASdk = MockSdk(),
                                          publicAlbumNodeProvider: any PublicAlbumNodeProviderProtocol = MockPublicAlbumNodeProvider()
    ) -> ShareAlbumRepository {
        ShareAlbumRepository(sdk: sdk, publicAlbumNodeProvider: publicAlbumNodeProvider)
    }
}
