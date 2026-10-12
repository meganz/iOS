@testable import MEGA
import MEGAAssets
import MEGADomain
import Testing
import UIKit

@MainActor
struct TextEditorBarItemsTests {
    private final class Target: NSObject, TextEditorBarItemTarget {
        func downloadTapped() {}
        func editTapped() {}
        func exportFileTapped(button: UIBarButtonItem) {}
        func importTapped() {}
    }

    private static let downloadAction = #selector((any TextEditorBarItemTarget).downloadTapped)
    private static let editAction = #selector((any TextEditorBarItemTarget).editTapped)
    private static let exportAction = #selector((any TextEditorBarItemTarget).exportFileTapped(button:))
    private static let importAction = #selector((any TextEditorBarItemTarget).importTapped)

    /// The items without the flexible spaces between them.
    private static func actionItems(_ accessLevel: NodeAccessTypeEntity, target: Target) -> [UIBarButtonItem] {
        TextEditorBarItems.bottomBarItems(accessLevel: accessLevel, target: target).filter { $0.action != nil }
    }

    @Test func ownerSeesDownloadEditExport() {
        let target = Target()

        let items = TextEditorBarItems.bottomBarItems(accessLevel: .owner, target: target)

        // Download, space, Edit, space, Export.
        #expect(items.count == 5)
        #expect(items.compactMap(\.image) == [MEGAAssets.UIImage.offline, MEGAAssets.UIImage.edittext, MEGAAssets.UIImage.downloadToDisk])
        #expect(items.compactMap(\.action) == [Self.downloadAction, Self.editAction, Self.exportAction])
        #expect(items.compactMap(\.action).count == 3)
    }

    @Test func fullAccessSeesDownloadEditImport() {
        let target = Target()

        let items = Self.actionItems(.full, target: target)

        #expect(items.map(\.action) == [Self.downloadAction, Self.editAction, Self.importAction])
        #expect(items.compactMap(\.image) == [MEGAAssets.UIImage.offline, MEGAAssets.UIImage.edittext, MEGAAssets.UIImage.import])
    }

    @Test func readAccessSeesDownloadImportWithoutEdit() {
        let target = Target()

        let items = Self.actionItems(.read, target: target)

        #expect(items.map(\.action) == [Self.downloadAction, Self.importAction])
        #expect(items.contains { $0.action == Self.editAction } == false)
    }

    @Test func unknownAccessSeesDownloadEditImport() {
        let target = Target()

        let items = Self.actionItems(.unknown, target: target)

        #expect(items.map(\.action) == [Self.downloadAction, Self.editAction, Self.importAction])
    }

    @Test func itemsTargetTheGivenObject() {
        let target = Target()
        let items = Self.actionItems(.owner, target: target)

        #expect(items.count == 3)
        #expect(items.allSatisfy { $0.target === target })
    }

    @Test func spacesAreBetweenItemsOnly() {
        let items = TextEditorBarItems.bottomBarItems(accessLevel: .read, target: Target())

        // Download, space, Import.
        #expect(items.count == 3)
        #expect(items[0].action != nil)
        #expect(items[1].action == nil)
        #expect(items[2].action != nil)
    }

    @Test func titleIsSetOnNavigationItem() {
        let navigationItem = UINavigationItem()

        TextEditorBarItems.applyTitle("notes.md", to: navigationItem, shouldEnableGlassEffect: false)

        if #available(iOS 26.0, *) {
            #expect(navigationItem.titleView != nil)
        } else {
            #expect(navigationItem.title == "notes.md")
        }
    }
}
