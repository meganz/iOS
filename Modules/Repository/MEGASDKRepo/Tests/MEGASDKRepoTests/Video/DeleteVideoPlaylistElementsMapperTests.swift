import MEGADomain
@testable import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class DeleteVideoPlaylistElementsMapperTests: XCTestCase {
    
    func testMap_whenRequestAndErrorNil_nil() {
        let result = DeleteVideoPlaylistElementsMapper.map(request: nil, error: nil)
        
        switch result {
        case .success(let setEntity):
            XCTFail("Expect to return error, got setEntity instead: \(setEntity)")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .invalidOperation)
        }
    }
    
    func testMap_whenError_returnsError() throws {
        let error = MockError(errorType: .apiEAccess)
        
        let result = try XCTUnwrap(DeleteVideoPlaylistElementsMapper.map(request: nil, error: error))
        
        switch result {
        case .success(let setEntity):
            XCTFail("Expect to return error, got setEntity instead: \(setEntity)")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .failedToDeleteVideoPlaylistElements)
        }
    }
    
    func testMap_whenSetIsNil_returnsError() throws {
        let request = MockRequest(handle: 1, set: nil)
        let error = MockError(errorType: .apiOk)
        
        let result = DeleteVideoPlaylistElementsMapper.map(request: request, error: error)
        
        switch result {
        case .success(let setEntity):
            XCTFail("Expect to return error, got setEntity instead: \(setEntity)")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .failedToRetrieveSetFromRequest)
        }
    }
    
    func testMap_whenApiOk_returnsSetEntity() throws {
        let request = MockRequest(handle: 1, set: MockMEGASet(handle: 2))
        let error = MockError(errorType: .apiOk)
        
        let result = DeleteVideoPlaylistElementsMapper.map(request: request, error: error)
        
        switch result {
        case .success(let setEntity):
            XCTAssertNotNil(setEntity)
        case .failure(let error):
            XCTFail("Expect to success, got error instead: \(error)")
        }
    }
}
