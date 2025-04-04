@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class DeleteVideoPlaylistElementsMapperTests: XCTestCase {
    
    func testMap_whenRequestAndErrorNil_nil() {
        let result = DeleteVideoPlaylistElementsMapper.map(request: nil, error: nil)
        
        switch result {
        case .success:
            XCTFail("Expect to return error, got success inteaed.")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .invalidOperation)
        }
    }
    
    func testMap_whenError_returnsError() throws {
        let error = MockError(errorType: .apiEAccess)
        
        let result = DeleteVideoPlaylistElementsMapper.map(request: nil, error: error)
        
        switch result {
        case .success:
            XCTFail("Expect to return error, got setEntity instead.")
        case .failure(let error):
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .failedToDeleteVideoPlaylistElements)
        }
    }
    
    func testMap_whenSuccess_successMap() throws {
        let request = MockRequest(handle: 1, set: nil)
        
        let result = DeleteVideoPlaylistElementsMapper.map(request: request, error: nil)
        
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
