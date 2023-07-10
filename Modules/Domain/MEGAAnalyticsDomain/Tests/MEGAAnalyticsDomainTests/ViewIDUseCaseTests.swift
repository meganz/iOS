import MEGAAnalyticsDomain
import MEGAAnalyticsDomainMock
import MEGATest
import XCTest

final class ViewIDUseCaseTests: XCTestCase {
    func testGenerateViewId_shouldReturnGeneratedViewId_onSuccess() throws {
        let (sut, mockViewIdRepo) = makeSUT()
        mockViewIdRepo._generateViewId = "expected-view-id"
        
        let viewID = try sut.generateViewId()
        
        XCTAssertEqual(viewID, "expected-view-id")
    }
    
    func testGenerateViewId_shouldThrowEmptyViewIDError_whenGotNilOrEmpty() {
        func assertThrowEmptyViewIDError(
            whenGenerateViewIdReturns generateViewId: ViewID?,
            line: UInt = #line
        ) {
            let (sut, mockViewIdRepo) = makeSUT(line: line)
            mockViewIdRepo._generateViewId = generateViewId
            
            XCTAssertThrowsError(try sut.generateViewId()) { error in
                XCTAssertEqual(
                    error as? ViewIDUseCase<MockViewIDRepository>.GenerationError,
                    .emptyViewID,
                    line: line
                )
            }
        }
        
        assertThrowEmptyViewIDError(whenGenerateViewIdReturns: "")
        assertThrowEmptyViewIDError(whenGenerateViewIdReturns: nil)
    }
    
    // MARK: - Test Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (ViewIDUseCase<MockViewIDRepository>, MockViewIDRepository) {
        let mockViewIdRepo = MockViewIDRepository()
        let sut = ViewIDUseCase(viewIdRepo: mockViewIdRepo)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockViewIdRepo)
    }
}
