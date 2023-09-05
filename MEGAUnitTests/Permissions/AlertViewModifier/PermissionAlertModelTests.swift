import Foundation
@testable import MEGA
import MEGAL10n
import XCTest

class PermissionAlertModelTests: XCTestCase {
    
    func testPhotos_SecondaryAction_shouldTriggerCompletion() {
        // Arrange
        var secondaryActionCalled = 0
        let sut = PermissionAlertModel.photo(completion: {
            secondaryActionCalled += 1
        })
        
        // Act
        sut.secondaryAction?.handler?()
        
        // Assert
        XCTAssertEqual(sut.title, Strings.Localizable.attention)
        XCTAssertEqual(sut.message, Strings.Localizable.photoLibraryPermissions)
        XCTAssertEqual(secondaryActionCalled, 1)
        
    }
    
    func testVideos_SecondaryAction_shouldTriggerCompletion() {
        // Arrange
        var secondaryActionCalled = 0
        let sut = PermissionAlertModel.video(completion: {
            secondaryActionCalled += 1
        })
        
        // Act
        sut.secondaryAction?.handler?()
        
        // Assert
        XCTAssertEqual(sut.title, Strings.Localizable.attention)
        XCTAssertEqual(sut.message, Strings.Localizable.cameraPermissions)
        XCTAssertEqual(secondaryActionCalled, 1)
    }
}
