@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

class CloudDriveViewModelTests: XCTestCase {
    
    func testUpdateEditModeActive_changeActiveToTrueWhenCurrentlyActive_shouldInvokeOnlyOnce() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(true))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode])
    }
    
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyNotActive_shouldInvokeNotInvoke() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(false))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [])
    }
    
    func testUpdateEditModeActive_changeActiveToFalseWhenCurrentlyActive_shouldInvokeEnterAndExitCommands() {
        
        // Arrange
        let sut = makeSUT()
        
        var commands = [CloudDriveViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        // Act
        sut.dispatch(.updateEditModeActive(true))
        sut.dispatch(.updateEditModeActive(false))
        
        // Assert
        XCTAssertEqual(commands, [.enterSelectionMode, .exitSelectionMode])
    }
        
    func makeSUT(
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase()) -> CloudDriveViewModel {
        
        CloudDriveViewModel(
            shareUseCase: shareUseCase)
    }
}
