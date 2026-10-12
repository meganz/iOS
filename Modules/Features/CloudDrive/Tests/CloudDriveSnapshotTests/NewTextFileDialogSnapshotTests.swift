@testable import CloudDrive
import MEGASnapshot
import SwiftUI
import Testing

/// Every test records a light and a dark image of the dialog.
/// Every state has one test per phone and text size: SE or ProMax, DefaultText or AccessibilityXL.
/// Each phone also has a landscape size, with the width and the height swapped.
@MainActor
@Suite(.serialized, .snapshot)
struct NewTextFileDialogSnapshotTests {
    private enum Phone {
        case se
        case proMax
        case seLandscape
        case proMaxLandscape

        var size: CGSize {
            switch self {
            case .se: CGSize(width: 375, height: 667)
            case .proMax: CGSize(width: 440, height: 956)
            case .seLandscape: CGSize(width: 667, height: 375)
            case .proMaxLandscape: CGSize(width: 956, height: 440)
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

    // MARK: - Text name, box off, landscape

    @Test func textName_SELandscape_DefaultText() {
        Self.record(fileName: "notes.txt", phone: .seLandscape)
    }

    @Test func textName_SELandscape_AccessibilityXL() {
        Self.record(fileName: "notes.txt", phone: .seLandscape, dynamicType: .accessibility3)
    }

    @Test func textName_ProMaxLandscape_DefaultText() {
        Self.record(fileName: "notes.txt", phone: .proMaxLandscape)
    }

    @Test func textName_ProMaxLandscape_AccessibilityXL() {
        Self.record(fileName: "notes.txt", phone: .proMaxLandscape, dynamicType: .accessibility3)
    }

    // MARK: - Markdown name, box on, landscape

    @Test func markdownName_SELandscape_DefaultText() {
        Self.record(fileName: "notes.md", phone: .seLandscape)
    }

    @Test func markdownName_SELandscape_AccessibilityXL() {
        Self.record(fileName: "notes.md", phone: .seLandscape, dynamicType: .accessibility3)
    }

    @Test func markdownName_ProMaxLandscape_DefaultText() {
        Self.record(fileName: "notes.md", phone: .proMaxLandscape)
    }

    @Test func markdownName_ProMaxLandscape_AccessibilityXL() {
        Self.record(fileName: "notes.md", phone: .proMaxLandscape, dynamicType: .accessibility3)
    }

    // MARK: - Invalid name, landscape

    @Test func invalidName_SELandscape_DefaultText() {
        Self.record(fileName: "notes?.txt", phone: .seLandscape)
    }

    @Test func invalidName_SELandscape_AccessibilityXL() {
        Self.record(fileName: "notes?.txt", phone: .seLandscape, dynamicType: .accessibility3)
    }

    @Test func invalidName_ProMaxLandscape_DefaultText() {
        Self.record(fileName: "notes?.txt", phone: .proMaxLandscape)
    }

    @Test func invalidName_ProMaxLandscape_AccessibilityXL() {
        Self.record(fileName: "notes?.txt", phone: .proMaxLandscape, dynamicType: .accessibility3)
    }

    // MARK: - Empty name, Create disabled, landscape

    @Test func emptyName_SELandscape_DefaultText() {
        Self.record(fileName: "", phone: .seLandscape)
    }

    @Test func emptyName_SELandscape_AccessibilityXL() {
        Self.record(fileName: "", phone: .seLandscape, dynamicType: .accessibility3)
    }

    @Test func emptyName_ProMaxLandscape_DefaultText() {
        Self.record(fileName: "", phone: .proMaxLandscape)
    }

    @Test func emptyName_ProMaxLandscape_AccessibilityXL() {
        Self.record(fileName: "", phone: .proMaxLandscape, dynamicType: .accessibility3)
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
