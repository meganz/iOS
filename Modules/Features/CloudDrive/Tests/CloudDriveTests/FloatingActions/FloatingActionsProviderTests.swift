@testable import CloudDrive
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import Testing

@Suite("FloatingActionsProvider Tests")
struct FloatingActionsProviderTests {
    @MainActor
    @Test("Test output of actions provider")
    func actions() {
        let handler = MockFloatingActionsHandler()
        let sut = FloatingActionsProvider(actionHandler: handler)
        let actions = sut.actions

        let actionIds = actions.map(\.id)
        #expect(actionIds == ["Choose from Photos", "Capture", "Import from Files", "Scan document", "New folder", "New text file", "Open link"])

        let actionTitles = actions.map(\.title)

        #expect(actionTitles == [
            "Choose from Photos",
            "Capture",
            "Import from Files",
            "Scan document",
            "New folder",
            "New text file",
            "Open link"
            ]
        )

        for action in actions {
            action.action()
        }

        #expect(handler.handledActions == [.chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile, .openLink])
    }
}

private final class MockFloatingActionsHandler: FloatingActionsHandlerProtocol, @unchecked Sendable {
    @Atomic var handledActions: [FloatingActionEntity] = []
    func handle(action: FloatingActionEntity) {
        $handledActions.mutate { $0.append(action) }
    }
}
