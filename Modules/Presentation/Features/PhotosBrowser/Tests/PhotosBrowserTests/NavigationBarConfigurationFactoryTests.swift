@testable import PhotosBrowser

import MEGAPresentation
import MEGATest
import XCTest

final class NavigationBarConfigurationFactoryTests: XCTestCase {

    func testNavConfig_cloudDriveDisplayMode_shouldReturnCloudDriveNavigationBarConfigurationStrategy() {
        // Given
        let displayMode: PhotosBrowserDisplayMode = .cloudDrive
        
        // When
        let config = NavigationBarConfigurationFactory.configuration(on: displayMode)
        
        // Then
        XCTAssertTrue(config is CloudDriveNavigationBarConfigurationStrategy, "Expected CloudDriveNavigationBarConfigurationStrategy but got \(type(of: config))")
    }
    
    func testNavConfig_chatAttachmentDisplayMode_shouldReturnChatAttachmentNavigationBarConfigurationStrategy() {
        // Given
        let displayMode: PhotosBrowserDisplayMode = .chatAttachment
        
        // When
        let config = NavigationBarConfigurationFactory.configuration(on: displayMode)
        
        // Then
        XCTAssertTrue(config is ChatAttachmentNavigationBarConfigurationStrategy, "Expected ChatAttachmentNavigationBarConfigurationStrategy but got \(type(of: config))")
    }
    
    // This will be changed when supporting file link mode
    func testNavConfig_fileLinkDisplayMode_shouldReturnCloudDriveNavigationBarConfigurationStrategy() {
        // Given
        let displayMode: PhotosBrowserDisplayMode = .fileLink
        
        // When
        let config = NavigationBarConfigurationFactory.configuration(on: displayMode)
        
        // Then
        XCTAssertTrue(config is CloudDriveNavigationBarConfigurationStrategy, "Expected CloudDriveNavigationBarConfigurationStrategy but got \(type(of: config))")
    }
}
