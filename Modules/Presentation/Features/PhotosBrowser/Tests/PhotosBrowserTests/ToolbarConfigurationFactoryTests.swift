@testable import PhotosBrowser

import MEGAPresentation
import MEGATest
import XCTest

final class ToolbarConfigurationFactoryTests: XCTestCase {

    func testToolbarConfig_cloudDriveDisplayMode_shouldReturnCloudDriveToolbarConfigurationStrategy() {
        // Given
        let displayMode: PhotosBrowserDisplayMode = .cloudDrive
        
        // When
        let config = ToolbarConfigurationFactory.configuration(on: displayMode)
        
        // Then
        XCTAssertTrue(config is CloudDriveToolbarConfigurationStrategy, "Expected CloudDriveToolbarConfigurationStrategy but got \(type(of: config))")
    }
    
    func testToolbarConfig_chatAttachmentDisplayMode_shouldReturnChatAttachmentConfigurationStrategy() {
        // Given
        let displayMode: PhotosBrowserDisplayMode = .chatAttachment
        
        // When
        let config = ToolbarConfigurationFactory.configuration(on: displayMode)
        
        // Then
        XCTAssertTrue(config is ChatAttachmenToolbarConfigurationStrategy, "Expected ChatAttachmenToolbarConfigurationStrategy but got \(type(of: config))")
    }
    
    // This will be changed when supporting file link mode
    func testToolbarConfig_fileLinkDisplayMode_shouldReturnCloudDriveToolbarConfigurationStrategy() {
        // Given
        let displayMode: PhotosBrowserDisplayMode = .fileLink
        
        // When
        let config = ToolbarConfigurationFactory.configuration(on: displayMode)
        
        // Then
        XCTAssertTrue(config is CloudDriveToolbarConfigurationStrategy, "Expected CloudDriveToolbarConfigurationStrategy but got \(type(of: config))")
    }
}
