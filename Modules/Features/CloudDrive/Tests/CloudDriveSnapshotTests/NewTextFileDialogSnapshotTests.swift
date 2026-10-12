@testable import CloudDrive
import MEGASnapshot
import SwiftUI
import Testing

/// Every test records a light and a dark image of the dialog.
/// Every state has one test per phone and text size: SE or ProMax, DefaultText or AccessibilityXL.
@MainActor
@Suite(.serialized, .snapshot)
struct NewTextFileDialogSnapshotTests {
    private enum Phone {
        case se
        case proMax

        var size: CGSize {
            switch self {
            case .se: CGSize(width: 375, height: 667)
            case .proMax: CGSize(width: 440, height: 956)
            }
        }
    }

    private static func makeDialog(fileName: String) -> NewTextFileDialogView {
        let viewModel = NewTextFileDialogViewModel(onCreate: { _ in }, onCancel: {})
        viewModel.setFileName(fileName)
        return NewTextFileDialogView(viewModel: viewModel, focusesOnAppear: false)
    }

    private static func record(
        fileName: String,
        phone: Phone,
        dynamicType: DynamicTypeSize = .large,
        layoutDirection: LayoutDirection = .leftToRight,
        testName: String = #function
    ) {
        assertSnapshot(
            of: makeDialog(fileName: fileName),
            width: phone.size.width,
            height: phone.size.height,
            dynamicType: dynamicType,
            layoutDirection: layoutDirection,
            testName: testName
        )
    }

    // MARK: - Text name, box off

    @Test func textName_SE_DefaultText() {
        Self.record(fileName: "notes.txt", phone: .se)
    }

    @Test func textName_SE_AccessibilityXL() {
        Self.record(fileName: "notes.txt", phone: .se, dynamicType: .accessibility3)
    }

    @Test func textName_ProMax_DefaultText() {
        Self.record(fileName: "notes.txt", phone: .proMax)
    }

    @Test func textName_ProMax_AccessibilityXL() {
        Self.record(fileName: "notes.txt", phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Markdown name, box on

    @Test func markdownName_SE_DefaultText() {
        Self.record(fileName: "notes.md", phone: .se)
    }

    @Test func markdownName_SE_AccessibilityXL() {
        Self.record(fileName: "notes.md", phone: .se, dynamicType: .accessibility3)
    }

    @Test func markdownName_ProMax_DefaultText() {
        Self.record(fileName: "notes.md", phone: .proMax)
    }

    @Test func markdownName_ProMax_AccessibilityXL() {
        Self.record(fileName: "notes.md", phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Invalid name

    @Test func invalidName_SE_DefaultText() {
        Self.record(fileName: "notes?.txt", phone: .se)
    }

    @Test func invalidName_SE_AccessibilityXL() {
        Self.record(fileName: "notes?.txt", phone: .se, dynamicType: .accessibility3)
    }

    @Test func invalidName_ProMax_DefaultText() {
        Self.record(fileName: "notes?.txt", phone: .proMax)
    }

    @Test func invalidName_ProMax_AccessibilityXL() {
        Self.record(fileName: "notes?.txt", phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Empty name, Create disabled

    @Test func emptyName_SE_DefaultText() {
        Self.record(fileName: "", phone: .se)
    }

    @Test func emptyName_SE_AccessibilityXL() {
        Self.record(fileName: "", phone: .se, dynamicType: .accessibility3)
    }

    @Test func emptyName_ProMax_DefaultText() {
        Self.record(fileName: "", phone: .proMax)
    }

    @Test func emptyName_ProMax_AccessibilityXL() {
        Self.record(fileName: "", phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Right to left

    @Test func newTextFileDialogRightToLeft() {
        Self.record(fileName: "notes.md", phone: .proMax, layoutDirection: .rightToLeft)
    }

    // MARK: - Dialog states

    @Test func newTextFileDialogUncheckedLight() {
        Self.record(fileName: "notes.txt", phone: .proMax)
    }

    @Test func newTextFileDialogCheckedLight() {
        Self.record(fileName: "notes.md", phone: .proMax)
    }

    @Test func newTextFileDialogUncheckedDark() {
        Self.record(fileName: "notes.txt", phone: .proMax)
    }

    @Test func newTextFileDialogCheckedDark() {
        Self.record(fileName: "notes.md", phone: .proMax)
    }

    @Test func newTextFileDialogInvalidNameLight() {
        Self.record(fileName: "notes?.txt", phone: .proMax)
    }

    @Test func newTextFileDialogCreateDisabled() {
        Self.record(fileName: "", phone: .proMax)
    }

    @Test func newTextFileDialogAccessibilityTextSize() {
        Self.record(fileName: "notes.md", phone: .proMax, dynamicType: .accessibility3)
    }
}
