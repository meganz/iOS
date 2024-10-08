@testable import MEGA
import MEGADomain
import Testing

@Suite("Quick Access Widget ViewModel Tests Suite - Testing widget actions and commands.")
struct QuickAccessWidgetViewModelTestSuite {
    // MARK: - Test Methods
    @Suite("Dispatch Action Tests")
    struct DispatchAction {
        static let anyBase64Handle = "someBase64Handle"
        static let anyLocalPath = "/path/to/file"
        
        // MARK: - Helper functions
        private static func makeSUT(
            mockOfflineFilesUseCase: MockOfflineFilesUseCase = MockOfflineFilesUseCase(),
            invokeCommand: @escaping (QuickAccessWidgetViewModel.Command) -> Void = { _ in }
        ) -> QuickAccessWidgetViewModel {
            let sut = QuickAccessWidgetViewModel(offlineFilesUseCase: mockOfflineFilesUseCase)
            sut.invokeCommand = invokeCommand
            return sut
        }
        
        private static func verifyInvokeCommand(
            for sut: QuickAccessWidgetViewModel,
            action: QuickAccessWidgetAction,
            expectedCommands: [QuickAccessWidgetViewModel.Command]
        ) {
            var invokedCommands: [QuickAccessWidgetViewModel.Command] = []
            sut.invokeCommand = { command in
                invokedCommands.append(command)
            }
            sut.dispatch(action)
            
            #expect(invokedCommands == expectedCommands, "Expected commands to match")
        }
        
        @Suite("Pending Action Dispatch")
        struct PendingActionDispatch {
            
            @Test("Will trigger .selectRecentsTab when dispatching pending action")
            func pendingActionDispatched() {
                let sut = DispatchAction.makeSUT()
                
                sut.invokeCommand = nil // Simulate that invokeCommand is unavailable, causing the action to be pending
                sut.dispatch(.showRecents)
                
                verifyInvokeCommand(for: sut, action: .managePendingAction, expectedCommands: [.selectRecentsTab])
            }
        }
        
        @Suite("Show Tab Actions")
        struct ShowTabActions {
            
            @Test("Will trigger .selectOfflineTab command")
            func invokeSelectOfflineTab() {
                verifyInvokeCommand(
                    for: makeSUT(),
                    action: .showOffline,
                    expectedCommands: [.selectOfflineTab]
                )
            }
            
            @Test("Will trigger .selectRecentsTab command")
            func invokeSelectRecentsTab() {
                verifyInvokeCommand(
                    for: makeSUT(),
                    action: .showRecents,
                    expectedCommands: [.selectRecentsTab]
                )
            }
            
            @Test("Will trigger .showFavourites command")
            func invokeShowFavourites() {
                verifyInvokeCommand(
                    for: makeSUT(),
                    action: .showFavourites,
                    expectedCommands: [.showFavourites]
                )
            }
        }
        
        @Suite("Show Favourites Node Actions")
        struct ShowFavouritesNodeActions {
            
            @Test("Will trigger .presentFavouritesNode command with base64 handle")
            func invokePresentFavouritesNode() {
                verifyInvokeCommand(
                    for: makeSUT(),
                    action: .showFavouritesNode(anyBase64Handle),
                    expectedCommands: [.presentFavouritesNode(anyBase64Handle)]
                )
            }
        }
        
        @Suite("Show Offline File Actions")
        struct ShowOfflineFileActions {
            
            @Test("Will trigger .selectOfflineTab and .presentOfflineFileWithPath commands")
            func invokePresentOfflineFile() {
                let offlineFile = OfflineFileEntity(
                    base64Handle: anyBase64Handle,
                    localPath: anyLocalPath,
                    parentBase64Handle: "",
                    fingerprint: "",
                    timestamp: Date()
                )
                verifyInvokeCommand(
                    for: makeSUT(mockOfflineFilesUseCase: MockOfflineFilesUseCase(offlineFile: offlineFile)),
                    action: .showOfflineFile(anyBase64Handle),
                    expectedCommands: [.selectOfflineTab, .presentOfflineFileWithPath(anyLocalPath)]
                )
            }
            
            @Test("Will trigger only .selectOfflineTab command when no file is found")
            func noFileFound() {
                verifyInvokeCommand(
                    for: makeSUT(mockOfflineFilesUseCase: MockOfflineFilesUseCase(offlineFile: nil)),
                    action: .showOfflineFile(anyBase64Handle),
                    expectedCommands: [.selectOfflineTab]
                )
            }
        }
    }
}
