import MEGADomain
@testable import MEGATextEditor
import Testing

struct MarkdownTextEditorBottomBarItemTests {
    @Test(arguments: [
        (NodeAccessTypeEntity.owner, [MarkdownTextEditorBottomBarItem.download, .edit, .export]),
        (.full, [.download, .edit, .import]),
        (.readWrite, [.download, .edit, .import]),
        (.read, [.download, .import]),
        (.unknown, [.download, .import])
    ])
    func bottomBarItemsFollowAccessLevel(accessType: NodeAccessTypeEntity, expected: [MarkdownTextEditorBottomBarItem]) {
        #expect(MarkdownTextEditorBottomBarItem.items(for: accessType) == expected)
    }
}
