@testable import MEGA
import MEGATest
import XCTest

final class EnterMeetingLinkViewModelTests: XCTestCase {
    
    @MainActor
    func testDidTapJoinButton_whenMeetingURLIsValid_shouldUpdateLinkURL() {
        // Given
        let urlString = "https://mock.mega.co.nz/chat"
        let expectedURL = URL(string: urlString)!
        let (sut, _, mockLinkManager) = makeSUT()
        
        // When
        sut.dispatch(.didTapJoinButton(urlString))
        
        // Then
        XCTAssertEqual(expectedURL, mockLinkManager.adapterLinkURL)
        XCTAssertNotNil(mockLinkManager.adapterLinkURL)
        XCTAssertEqual((mockLinkManager.adapterLinkURL! as NSURL).mnz_type(), .publicChatLink)
    }
    
    @MainActor
    func testDidTapJoinButton_whenMeetingURLIsInValid_shouldShowLinkError() {
        // Given
        let urlString = "malformed_string_url"
        let (sut, mockRouter, _) = makeSUT()
        
        // When
        sut.dispatch(.didTapJoinButton(urlString))
        
        // Then
        XCTAssertTrue(mockRouter.showLinkErrorCalled)
    }
    
    @MainActor
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        EnterMeetingLinkViewModel,
        MockEnterMeetingLinkRouter,
        any MEGALinkManagerProtocol.Type
    ) {
        let mockRouter = MockEnterMeetingLinkRouter()
        let mockLinkManager = MockLinkManager.self
        let sut = EnterMeetingLinkViewModel(
            router: mockRouter,
            linkManager: mockLinkManager
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockRouter, mockLinkManager)
    }

}
