import XCTest
import MEGASdk
import MEGAData
import MEGADomain
import MEGADataMock

class ShareAlbumRepositoryTests: XCTestCase {
    func testShareAlbum_onSuccess_shouldReturnLink() async throws {
        let expectedLink = "the_shared_link"
        let mockSdk = MockSdk(link: expectedLink)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        let result = try await sut.shareAlbum(by: 1)
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareAlbum_onBuisinessPastDue_shouldThrowError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBusinessPastDue)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.shareAlbum(by: 1)
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity, ShareAlbumErrorEntity.buisinessPastDue)
        }
    }
    
    func testShareAlbum_onOtherError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            _ = try await sut.shareAlbum(by: 1)
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
    
    func testDisableAlbumShare_onSuccess_shouldComplete() async throws {
        let sut = ShareAlbumRepository(sdk: MockSdk())
        try await sut.disableAlbumShare(by: 1)
    }
    
    func testDisableAlbumShare_onBuisinessPastDue_shouldThrowError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBusinessPastDue)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            try await sut.disableAlbumShare(by: 1)
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity, ShareAlbumErrorEntity.buisinessPastDue)
        }
    }
    
    func testDisableAlbumShare_onOtherError_shouldThrowGenericError() async {
        let mockSdk = MockSdk(megaSetError: .apiEBlocked)
        let sut = ShareAlbumRepository(sdk: mockSdk)
        do {
            try await sut.disableAlbumShare(by: 1)
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
        let sut = ShareAlbumRepository(sdk:sdk)
        let result = try await sut.publicAlbumContents(forLink: "public_link")
        XCTAssertEqual(result.set, expectedSet.toSetEntity())
        XCTAssertEqual(result.setElements, expectedSetElements.toSetElementsEntities())
    }
    
    func testPublicAlbumContents_onSDKNotOkKnownError_shouldThrowCorrectError() async {
        let testCase = [(MEGAErrorType.apiENoent, SharedAlbumErrorEntity.resourceNotFound),
                        (.apiEInternal, .couldNotBeReadOrDecrypted),
                        (.apiEArgs, .malformed),
                        (.apiEAccess, .permissionError),
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
}
