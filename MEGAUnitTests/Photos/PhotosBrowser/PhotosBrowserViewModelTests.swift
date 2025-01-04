@preconcurrency import PhotosBrowser
import Testing
import XCTest

final class PhotosBrowserViewModelXCTests: XCTestCase {
    
    @MainActor
    func testPhotosBrower_onPageIndexChange_onCurrentIndexChangeCommandShouldBeCalledTwice() {
        let expectation = expectation(description: "invokeCommand should be called with .onCurrentIndexChange")
        expectation.expectedFulfillmentCount = 2
        
        var receivedCommands: [PhotosBrowserViewModel.Command] = []
        
        let mediaLibrary = MediaLibrary(assets: [], currentIndex: 0)
        let config = PhotosBrowserConfiguration(displayMode: .cloudDrive, library: mediaLibrary)
        let viewModel = PhotosBrowserViewModel(config: config)
        
        viewModel.invokeCommand = { command in
            receivedCommands.append(command)
            expectation.fulfill()
        }
        
        mediaLibrary.currentIndex = 1
        mediaLibrary.currentIndex = 2
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedCommands, [
            .onCurrentIndexChange(1),
            .onCurrentIndexChange(2)
        ])
    }
}

struct PhotosBrowserViewModelTests {
    
    @Suite("Calls Dispatch Action")
    struct PhotosBrowserActionTests {
        @Test("When action is onViewReady, it will invoke command .onViewReady")
        func onViewReadyCommand() async {
            var receivedCommand: PhotosBrowserViewModel.Command?
            
            await confirmation("invokeCommand should be called with .onViewReady") { @MainActor confirm in
                let sut = PhotosBrowserViewModel(config: PhotosBrowserConfiguration(displayMode: .cloudDrive,
                                                                                    library: .init(assets: [], currentIndex: 0)))
                sut.invokeCommand = { command in
                    receivedCommand = command
                    confirm()
                }
                
                sut.dispatch(.onViewReady)
            }
            
            #expect(receivedCommand == PhotosBrowserViewModel.Command.onViewReady)
        }
    }
}
