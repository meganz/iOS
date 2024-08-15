import PhotosBrowser
import XCTest

final class PhotosBrowserViewModelTests: XCTestCase {
    
    func testAction_onViewReady_called() {
        let sut = makeSUT()
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.onViewReady])
    }
    
    // Private: - Sut Creation
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> PhotosBrowserViewModel {
        let sut = PhotosBrowserViewModel(config: PhotosBrowserConfiguration(displayMode: .cloudDrive))
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        
        return sut
    }
}
