import Combine
@testable import ContentLibraries
import XCTest

final class PhotoZoomControlPositionTrackerTests: XCTestCase {
    
    func testTrackContentOffset_whenTrackedOffsetIsBetweenBaseAndMax_shouldTrackScrollOffset() async {
        
        // Arrange
        let baseOffset: CGFloat = 5
        let viewSpace: CGFloat = 50
        let sut = PhotoZoomControlPositionTracker(
            shouldTrackScrollOffsetPublisher: Just(true),
            baseOffset: baseOffset)
        
        sut.update(viewSpace: viewSpace)
        
        // Act
        sut.trackContentOffset(30)
        
        // Assert
        let expectedResult: CGFloat = 20
        let result = await sut.$viewOffset
            .values
            .first { $0 == expectedResult }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTrackContentOffset_whenTrackedOffsetIsAboveMaxOffset_shouldReturnBaseOffset() async {
        
        // Arrange
        let baseOffset: CGFloat = 5
        let viewSpace: CGFloat = 50
        let sut = PhotoZoomControlPositionTracker(
            shouldTrackScrollOffsetPublisher: Just(true),
            baseOffset: baseOffset)
        
        sut.update(viewSpace: viewSpace)
        
        // Act
        sut.trackContentOffset(60)
        
        // Assert
        let expectedResult = baseOffset
        let result = await sut.$viewOffset
            .values
            .first { $0 == expectedResult }
            
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTrackContentOffset_whenTrackedOffsetIsBelowBaseOffset_shouldReturnViewSpace() async {
        
        // Arrange
        let baseOffset: CGFloat = 5
        let viewSpace: CGFloat = 50
        let sut = PhotoZoomControlPositionTracker(
            shouldTrackScrollOffsetPublisher: Just(true),
            baseOffset: baseOffset)
        sut.update(viewSpace: viewSpace)
        
        // Act
        sut.trackContentOffset(-10)
        
        // Assert
        let expectedResult = viewSpace + baseOffset
        let result = await sut.$viewOffset
            .values
            .first { $0 == expectedResult }
            
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTrackContentOffset_whenTrackedOffsetIsBetweenBaseAndMaxAndShowEnableCameraUploadIsFalse_shouldReturnBaseOffset() async {
        
        // Arrange
        let baseOffset: CGFloat = 5
        let viewSpace: CGFloat = 50
        let sut = PhotoZoomControlPositionTracker(
            shouldTrackScrollOffsetPublisher: Just(false),
            baseOffset: baseOffset)
        
        sut.update(viewSpace: viewSpace)
        
        // Act
        sut.trackContentOffset(30)
        
        // Assert
        let expectedResult = baseOffset
        let result = await sut.$viewOffset
            .values
            .first { $0 == expectedResult }
            
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTrackContentOffset_whenTrackedOffsetIsAboveMaxOffsetAndShowEnableCameraUploadIsFalse_shouldReturnBaseOffset() async {
        
        // Arrange
        let baseOffset: CGFloat = 5
        let viewSpace: CGFloat = 50
        let sut = PhotoZoomControlPositionTracker(
            shouldTrackScrollOffsetPublisher: Just(false),
            baseOffset: baseOffset)
        sut.update(viewSpace: viewSpace)
        
        // Act
        sut.trackContentOffset(51)
        
        // Assert
        let expectedResult = baseOffset
        let result = await sut.$viewOffset
            .values
            .first { $0 == expectedResult }
            
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTrackContentOffset_whenTrackedOffsetIsBelowBaseOffsetAndShowEnableCameraUploadIsFalse_shouldReturnBaseOffset() async {
        
        // Arrange
        let baseOffset: CGFloat = 5
        let viewSpace: CGFloat = 50
        let sut = PhotoZoomControlPositionTracker(
            shouldTrackScrollOffsetPublisher: Just(false),
            baseOffset: baseOffset)
        sut.update(viewSpace: viewSpace)
        
        // Act
        sut.trackContentOffset(-10)
        
        // Assert
        let expectedResult = baseOffset
        let result = await sut.$viewOffset
            .values
            .first { $0 == expectedResult }
            
        XCTAssertEqual(result, expectedResult)
    }
}
