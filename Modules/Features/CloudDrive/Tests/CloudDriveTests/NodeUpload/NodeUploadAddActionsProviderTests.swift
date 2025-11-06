@testable import CloudDrive
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import Testing

@Suite("NodeUploadAddActionsProvider Tests")
struct NodeUploadAddActionsProviderTests {
    @MainActor
    @Test("Test output of actions provider")
    func actions() {
        let handler = MockNodeUploadAddActionsHandler()
        let sut = NodeUploadAddActionsProvider(actionHandler: handler)
        let actions = sut.actions

        let actionEntities = actions.map(\.actionEntity)
        #expect(actionEntities == [.chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile])

        let actionTitles = actions.map(\.title)

        #expect(actionTitles == [
            "Choose from Photos",
            "Capture",
            "Import from Files",
            "Scan document",
            "New folder",
            "New text file"]
        )

        for action in actions {
            action.action()
        }

        #expect(handler.handledActions == [.chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile])
    }
}

private final class MockNodeUploadAddActionsHandler: NodeUploadAddActionsHandlerProtocol, @unchecked Sendable {
    @Atomic var handledActions: [UploadAddActionEntity] = []
    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        $handledActions.mutate { $0.append(action) }
    }
}
