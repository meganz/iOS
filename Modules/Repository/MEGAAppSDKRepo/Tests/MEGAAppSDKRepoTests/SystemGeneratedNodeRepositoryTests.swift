import AsyncAlgorithms
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class SystemGeneratedNodeRepositoryTests: XCTestCase {
    
    func testNodeForLocations_shouldReturnCorrectNode() async throws {
        for await location in SystemGeneratedFolderLocationEntity.allCases.async {
            
            let expectedResult = nodesFor(location: location)
            let sut = sut(
                cameraUploadNodeResult: nodesFor(location: .cameraUpload),
                mediaUploadNodeResult: nodesFor(location: .mediaUpload),
                myChatUploadNodeResult: nodesFor(location: .myChatFiles))
            let result = try await sut.node(for: location)
            
            XCTAssertEqual(result, try XCTUnwrap(try expectedResult.get().toNodeEntity()), "Node for \(location) should be \(String(describing: expectedResult))")
        }
    }
    
    func testNodeForLocations_whenNodeDoesNotExist_shouldThrowNodeDoesNotExistError() async throws {
        for await location in SystemGeneratedFolderLocationEntity.allCases.async {
            
            let sut = sut(
                cameraUploadNodeResult: nodesFor(location: .cameraUpload, failedLocation: location),
                mediaUploadNodeResult: nodesFor(location: .mediaUpload, failedLocation: location),
                myChatUploadNodeResult: nodesFor(location: .myChatFiles, failedLocation: location))
            
            do {
                _ = try await sut.node(for: location)
                XCTFail("Should have thrown error")
            } catch let error as SystemGeneratedFolderLocationErrorEntity {
                XCTAssertEqual(error, SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist(location: location))
            } catch {
                XCTFail("Invalid error thrown")
            }
        }
    }
}

extension SystemGeneratedNodeRepositoryTests {
    
    func nodesFor(location: SystemGeneratedFolderLocationEntity, failedLocation: SystemGeneratedFolderLocationEntity? = nil) -> Result<MEGANode, any Error> {
        switch location {
        case .cameraUpload where failedLocation != location:
            .success(MockNode(handle: 1))
        case .mediaUpload where failedLocation != location:
            .success(MockNode(handle: 2))
        case .myChatFiles where failedLocation != location:
            .success(MockNode(handle: 3))
        default:
            .failure(GenericErrorEntity())
        }
    }
    
    func sut(
        cameraUploadNodeResult: Result<MEGANode, any Error> = .failure(GenericErrorEntity()),
        mediaUploadNodeResult: Result<MEGANode, any Error> = .failure(GenericErrorEntity()),
        myChatUploadNodeResult: Result<MEGANode, any Error> = .failure(GenericErrorEntity())
    ) -> SystemGeneratedNodeRepository {
            
        .init(
            cameraUploadNodeAccess: MockNodeAccess(result: cameraUploadNodeResult),
            mediaUploadNodeAccess: MockNodeAccess(result: mediaUploadNodeResult),
            myChatFilesFolderNodeAccess: MockNodeAccess(result: myChatUploadNodeResult))
    }
}
