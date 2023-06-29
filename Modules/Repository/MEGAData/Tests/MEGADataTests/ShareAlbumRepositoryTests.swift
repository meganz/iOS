import MEGAData
import MEGADataMock
import MEGADomain
import MEGASdk
import XCTest

class ShareAlbumRepositoryTests: XCTestCase {
    func testShareAlbumLink_onAlbumThatsNotShared_shouldReturnSharedLink() async throws {
        let expectedLink = "the_shared_link"
        let mockSdk = MockSdk(link: expectedLink)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        let result = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false)))
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareAlbumLink_onAlbumThatsShared_shouldReturnExistingSharedLink() async throws {
        let expectedLink = "the_existing_shared_link"
        let mockSdk = MockSdk(link: expectedLink)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        let result = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true)))
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareAlbum_onBuisinessPastDue_shouldThrowError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBusinessPastDue)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false)))
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity, ShareAlbumErrorEntity.buisinessPastDue)
        }
    }
    
    func testShareAlbum_onOtherError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.shareAlbumLink(AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(false)))
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testDisableAlbumShare_onSuccess_shouldComplete() async throws {
        let sut = ShareAlbumRepository(sdk: MockSdk())
        try await sut.removeSharedLink(forAlbumId: 1)
    }
    
    func testDisableAlbumShare_onBuisinessPastDue_shouldThrowError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBusinessPastDue)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            try await sut.removeSharedLink(forAlbumId: 1)
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity, ShareAlbumErrorEntity.buisinessPastDue)
        }
    }
    
    func testDisableAlbumShare_onOtherError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = ShareAlbumRepository(sdk: mockSdk)
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
        let sut = ShareAlbumRepository(sdk: sdk)
        let result = try await sut.publicAlbumContents(forLink: "public_link")
        XCTAssertEqual(result.set, expectedSet.toSetEntity())
        XCTAssertEqual(result.setElements, expectedSetElements.toSetElementsEntities())
    }
    
    func testPublicAlbumContents_onSDKNotOkKnownError_shouldThrowCorrectError() async {
        let testCase = [(MEGAErrorType.apiENoent, SharedAlbumErrorEntity.resourceNotFound),
                        (.apiEInternal, .couldNotBeReadOrDecrypted),
                        (.apiEArgs, .malformed),
                        (.apiEAccess, .permissionError)
        ]
        
        let result = await withTaskGroup(of: Bool.self) { group in
            testCase.forEach { testCase in
                group.addTask {
                    let mockSdk = MockSdk(megaSetError: testCase.0)
                    let sut = ShareAlbumRepository(sdk: mockSdk)
                    do {
                        _ = try await sut.publicAlbumContents(forLink: "public_link")
                        return false
                    } catch {
                        return error as? SharedAlbumErrorEntity == testCase.1
                    }
                }
            }
            
            return await group.reduce(into: [Bool](), {
                $0.append($1)
            })
        }
        XCTAssertTrue(result.isNotEmpty)
        XCTAssertFalse(result.contains(where: { !$0 }))
    }
    
    func testPublicAlbumContents_onSDKNotOkUnknownError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.publicAlbumContents(forLink: "public_link")
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testPublicPhoto_onSuccessfullResponse_shouldReturnPhotoNode() async throws {
        let photoId: UInt64 = 5
        let photo = MockNode(handle: photoId)
        let sdk = MockSdk(nodes: [photo])
        let sut = ShareAlbumRepository(sdk: sdk)
        
        let result = try await sut.publicPhoto(forPhotoId: photoId)
        
        XCTAssertEqual(result, photo.toNodeEntity())
    }
    
    func testPublicPhoto_onSDKNotOkKnownError_shouldThrowCorrectError() async {
        let testCase = [(MEGAErrorType.apiEArgs, SharedPhotoErrorEntity.photoNotFound),
                        (.apiEAccess, .previewModeNotEnabled)
        ]
        
        let result = await withTaskGroup(of: Bool.self) { group in
            testCase.forEach { testCase in
                group.addTask {
                    let mockSdk = MockSdk(megaSetError: testCase.0)
                    let sut = ShareAlbumRepository(sdk: mockSdk)
                    do {
                        _ = try await sut.publicPhoto(forPhotoId: HandleEntity(6))
                        return false
                    } catch {
                        return error as? SharedPhotoErrorEntity == testCase.1
                    }
                }
            }
            return await group.reduce(into: [Bool](), {
                $0.append($1)
            })
        }
        XCTAssertTrue(result.isNotEmpty)
        XCTAssertFalse(result.contains(where: { !$0 }))
    }
    
    func testPublicPhoto_onSDKNotOkUnknownError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        
        do {
            _ = try await sut.publicPhoto(forPhotoId: HandleEntity(6))
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
}
