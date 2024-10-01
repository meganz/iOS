@preconcurrency import PhotosBrowser
import Testing

struct PhotosBrowserViewModelTests {
    
    @Test("onViewReady Command should be called with .onViewReady action")
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
