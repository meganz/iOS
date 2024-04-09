import MEGADomain
@testable import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class AddVideosToVideoPlaylistResultMapperTests: XCTestCase {
    
    func testMap_whenRequestAndErrorNil_nil() {
        let result = AddVideosToVideoPlaylistResultMapper.map(request: nil, error: nil)
        
        XCTAssertNil(result, "Expect to not map anyting on request and error nil")
    }
    
    func testMap_whenError_returnsError() throws {
        let error = MockError(errorType: .apiEAccess)
        
        let result = try XCTUnwrap(AddVideosToVideoPlaylistResultMapper.map(request: nil, error: error))
        
        switch result {
        case .success(let setEntity):
            XCTFail("Expect to return error, got setEntity instead: \(setEntity)")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .failedToAddVideoToPlaylist)
        }
    }
    
    func testMap_whenSetIsNil_returnsError() throws {
        let request = MockRequest(handle: 1, set: nil)
        let error = MockError(errorType: .apiOk)
        
        let result = try XCTUnwrap(AddVideosToVideoPlaylistResultMapper.map(request: request, error: error))
        
        switch result {
        case .success(let setEntity):
            XCTFail("Expect to return error, got setEntity instead: \(setEntity)")
        case .failure(let error):
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    func testMap_whenApiOk_returnsSetEntity() throws {
        let request = MockRequest(handle: 1, set: MockMEGASet(handle: 2))
        let error = MockError(errorType: .apiOk)
        
        let result = try XCTUnwrap(AddVideosToVideoPlaylistResultMapper.map(request: request, error: error))
        
        switch result {
        case .success(let setEntity):
            XCTAssertNotNil(setEntity)
        case .failure(let error):
            XCTFail("Expect to success, got error instead: \(error)")
        }
    }

}
