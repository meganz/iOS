@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class AddVideosToVideoPlaylistResultMapperTests: XCTestCase {
    
    func testMap_whenRequestAndErrorNil_nil() {
        let result = AddVideosToVideoPlaylistResultMapper.map(request: nil, error: nil)
        
        switch result {
        case .success:
            XCTFail("Expect to return error, got success instead.")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .invalidOperation)
        }
    }
    
    func testMap_whenError_returnsError() throws {
        let error = MockError(errorType: .apiEAccess)
        
        let result = AddVideosToVideoPlaylistResultMapper.map(request: nil, error: error)
        
        switch result {
        case .success:
            XCTFail("Expect to return error, got success intead.")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .failedToAddVideoToPlaylist)
        }
    }
    
    func testMap_whenSuccess_successMap() throws {
        let request = MockRequest(handle: 1, set: nil)
        
        let result = AddVideosToVideoPlaylistResultMapper.map(request: request, error: nil)
        
        var isSuccessMapping = false
        switch result {
        case .success:
            isSuccessMapping = true
        case .failure(let error):
            XCTFail("Expect to success mapping, got error instead: \(error)")
        }
        
        XCTAssertTrue(isSuccessMapping)
    }

}
