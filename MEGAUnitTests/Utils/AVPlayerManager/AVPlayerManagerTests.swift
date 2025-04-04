import Foundation
@testable import MEGA
import MEGAAppSDKRepoMock
import XCTest

class AVPlayerManagerTests: XCTestCase {

    func testIsPIPModeActive_forValidController_shouldBeTrue() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let controller = try XCTUnwrap(MEGAAVViewController(url: videoURL))
        
        // Act
        manager.playerViewControllerWillStartPictureInPicture(controller)
        
        // Assert
        XCTAssertTrue(manager.isPIPModeActive(for: controller), "Expected avplayercontroller to be in PIP mode")
    }
    
    func testIsPIPModeActive_forInvalidController_shouldBeFalse() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let controller = try XCTUnwrap(MEGAAVViewController(url: videoURL))
        
        let secondVideoURL = try XCTUnwrap(URL(string: "file://videos/abc2.mp4"))
        let secondController = try XCTUnwrap(MEGAAVViewController(url: secondVideoURL))

        // Act
        manager.playerViewControllerWillStartPictureInPicture(controller)
        
        // Assert
        XCTAssertFalse(manager.isPIPModeActive(for: secondController), "Expected avplayercontroller to not be in PIP mode")
        XCTAssertTrue(manager.isPIPModeActive(for: controller), "Expected first avplayercontroller to be in PIP mode")
    }
    
    func testIsPIPModeActive_forValidControllerAndHasStoppedPIP_shouldBeFalse() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let controller = try XCTUnwrap(MEGAAVViewController(url: videoURL))

        // Act
        manager.playerViewControllerWillStartPictureInPicture(controller)
        XCTAssertTrue(manager.isPIPModeActive(for: controller), "Expected avplayercontroller to be in PIP mode")
        manager.playerViewControllerDidStopPictureInPicture(controller)

        // Assert
        XCTAssertFalse(manager.isPIPModeActive(for: controller), "Expected avplayercontroller to not be in PIP mode")
    }
    
    func testMakePlayerControllerInitWithURL_whenSecondControllerRequestedIsTheSameContentAsFirstActivePIPController_returnsSameCurrentActiveController() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))

        let controller = manager.makePlayerController(for: videoURL)
        manager.playerViewControllerWillStartPictureInPicture(controller)
        
        // Act
        let secondController = manager.makePlayerController(for: videoURL)
        
        // Assert
        XCTAssertEqual(controller, secondController)
    }
    
    func testMakePlayerControllerInitWithURL_whenSecondControllerRequestedIsTheSameContentAsFirstNonActivePIPController_returnsNewController() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))

        let controller = manager.makePlayerController(for: videoURL)
        
        // Act
        let secondController = manager.makePlayerController(for: videoURL)
        
        // Assert
        XCTAssertNotEqual(controller, secondController)
    }
    
    func testMakePlayerControllerInitWithURL_whenSecondControllerRequestedIsNotTheSameContentAsFirstActivePIPController_returnsNewController() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let videoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))

        let controller = manager.makePlayerController(for: videoURL)
        
        // Act
        let secondVideoURL = try XCTUnwrap(URL(string: "file://videos/abc.mp4"))
        let secondController = manager.makePlayerController(for: secondVideoURL)
        
        // Assert
        XCTAssertNotEqual(controller, secondController)
    }
    
    func testMakePlayerControllerInitWithNode_whenSecondControllerRequestedIsTheSameContentAsFirstActivePIPController_returnsCurrentActiveController() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        let node = MockNode(handle: 0, fingerprint: "12345")
        let controller = manager.makePlayerController(for: node, folderLink: false, sdk: mockSDK)
        manager.playerViewControllerWillStartPictureInPicture(controller)
        
        // Act
        let secondController = manager.makePlayerController(for: node, folderLink: false, sdk: mockSDK)
        
        // Assert
        XCTAssertEqual(controller, secondController)
    }
    
    func testMakePlayerControllerInitWithNode_whenSecondControllerRequestedIsTheSameContentAsFirstNonActivePIPController_returnsNewController() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let node = MockNode(handle: 0, fingerprint: "12345")

        let controller = manager.makePlayerController(for: node, folderLink: false, sdk: mockSDK)
        
        // Act
        let secondController = manager.makePlayerController(for: node, folderLink: false, sdk: mockSDK)
        
        // Assert
        XCTAssertNotEqual(controller, secondController)
    }
    
    func testMakePlayerControllerInitWithNode_whenSecondControllerRequestedIsDifferentContentAsFirstActivePIPController_returnsNewController() throws {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let manager = AVPlayerManager(sdk: mockSDK)
        
        let node = MockNode(handle: 0, fingerprint: "12345")

        let controller = manager.makePlayerController(for: node, folderLink: false, sdk: mockSDK)
        manager.playerViewControllerWillStartPictureInPicture(controller)

        // Act
        let secondNode = MockNode(handle: 0, fingerprint: "54321")
        let secondController = manager.makePlayerController(for: secondNode, folderLink: false, sdk: mockSDK)
        
        // Assert
        XCTAssertNotEqual(controller, secondController)
    }
}
