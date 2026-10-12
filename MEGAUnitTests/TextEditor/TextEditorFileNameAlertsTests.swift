@testable import MEGA
import MEGAL10n
import Testing
import UIKit

@MainActor
struct TextEditorFileNameAlertsTests {
    private static let renameModel = TextEditorRenameAlertModel(
        alertTitle: "Rename",
        alertMessage: "Enter the new name",
        cancelButtonTitle: "Cancel",
        renameButtonTitle: "Rename",
        textFileName: "notes.md"
    )

    private static func renameAction(of alert: UIAlertController) -> UIAlertAction? {
        alert.actions.first { $0.title == Strings.Localizable.rename }
    }

    private static func type(_ text: String, in alert: UIAlertController) {
        guard let textField = alert.textFields?.first else { return }
        textField.text = text
        textField.sendActions(for: .editingChanged)
    }

    @Test func duplicateNameAlertHasRenameReplaceCancel() {
        let model = TextEditorDuplicateNameAlertModel(
            alertTitle: "Name taken",
            alertMessage: "A file with this name exists",
            cancelButtonTitle: "Cancel",
            replaceButtonTitle: "Replace",
            renameButtonTitle: "Rename"
        )

        let alert = TextEditorFileNameAlerts.makeDuplicateNameAlert(model, onRename: {}, onReplace: {})

        #expect(alert.title == "Name taken")
        #expect(alert.message == "A file with this name exists")
        #expect(alert.preferredStyle == .alert)
        #expect(alert.actions.map(\.title) == ["Rename", "Replace", "Cancel"])
        #expect(alert.actions.map(\.style) == [.default, .default, .cancel])
    }

    @Test func renameAlertStartsWithRenameDisabled() throws {
        let alert = TextEditorFileNameAlerts.makeRenameAlert(Self.renameModel) { _ in }

        let textField = try #require(alert.textFields?.first)
        #expect(textField.text == "notes.md")
        #expect(textField.placeholder == "notes.md")
        #expect(try #require(Self.renameAction(of: alert)).isEnabled == false)
    }

    @Test func renameAlertEnablesRenameForNewValidName() throws {
        let alert = TextEditorFileNameAlerts.makeRenameAlert(Self.renameModel) { _ in }

        Self.type("other.md", in: alert)

        #expect(try #require(Self.renameAction(of: alert)).isEnabled)
    }

    @Test func renameAlertDisablesRenameForInvalidName() throws {
        let alert = TextEditorFileNameAlerts.makeRenameAlert(Self.renameModel) { _ in }
        let rename = try #require(Self.renameAction(of: alert))

        Self.type("other.md", in: alert)
        Self.type("bad/name.md", in: alert)
        #expect(rename.isEnabled == false)

        Self.type("other.md", in: alert)
        Self.type("", in: alert)
        #expect(rename.isEnabled == false)

        Self.type("other.md", in: alert)
        Self.type("notes.md", in: alert)
        #expect(rename.isEnabled == false)
    }
}
