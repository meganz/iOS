import MEGADesignToken
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

// MARK: - Trait

extension Trait where Self == ConditionTrait {
    /// Runs the test only from `scripts/snapshot.sh`. Other test runs skip it.
    /// Images need a pinned simulator, so a normal package test run would fail.
    public static var snapshot: Self {
        .enabled(if: ProcessInfo.processInfo.environment["MEGA_SNAPSHOT"] == "1", "Run with scripts/snapshot.sh")
    }
}

// MARK: - Device check

/// Images depend on the OS runtime and the screen scale, not on the device model.
/// UIKit fonts read the simulator text size, not the snapshot trait, so it must be the default.
@MainActor
func checkSnapshotDevice(sourceLocation: SourceLocation = #_sourceLocation) -> Bool {
    let version = UIDevice.current.systemVersion
    let scale = UIScreen.main.scale
    guard version.hasPrefix("26.4"), scale == 3 else {
        Issue.record("Snapshots need an iOS 26.4 simulator at 3x. Got \(version) @\(scale)x.", sourceLocation: sourceLocation)
        return false
    }
    // Without a host app the size category reads empty, so check the body font UIKit gives.
    let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
    guard bodySize == 17 else {
        let message = "Snapshots need the simulator text size large (body 17pt). Got \(bodySize)pt. Run: xcrun simctl ui <udid> content_size large"
        Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
        return false
    }
    // Text styles get taller lines when a preferred language such as Vietnamese needs more space.
    // UIKit text follows the simulator languages, so they must be English only.
    let languages = Locale.preferredLanguages
    guard languages.allSatisfy({ $0.hasPrefix("en") }) else {
        let message = "Snapshots need English as the only simulator language. Got \(languages). Run scripts/snapshot.sh, which sets it."
        Issue.record(Comment(rawValue: message), sourceLocation: sourceLocation)
        return false
    }
    return true
}

// MARK: - Assert

/// Records one light and one dark image of `view`.
/// The images go to `__Snapshots__/<test file name>/` next to the calling test file.
@MainActor
public func assertSnapshot(
    of view: some View,
    width: CGFloat = 402,
    height: CGFloat? = nil,
    dynamicType: DynamicTypeSize = .large,
    layoutDirection: LayoutDirection = .leftToRight,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let sourceLocation = SourceLocation(
        fileID: String(describing: fileID),
        filePath: String(describing: filePath),
        line: Int(line),
        column: Int(column)
    )
    guard checkSnapshotDevice(sourceLocation: sourceLocation) else { return }
    // The measure below runs before the size trait applies, so large text would be cut off.
    guard !dynamicType.isAccessibilitySize || height != nil else {
        Issue.record("Accessibility sizes need a fixed height.", sourceLocation: sourceLocation)
        return
    }
    UIView.setAnimationsEnabled(false)

    let content = view
        .frame(width: width, height: height, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .environment(\.locale, Locale(identifier: "en_US"))
        // SwiftUI picks the line height from the typesetting language, not from the locale above.
        .typesettingLanguage(.init(languageCode: .english))
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.dynamicTypeSize, dynamicType)
        .transaction { $0.animation = nil }
    // The library's `.sizeThatFits` proposes a zero size: wrapping text and code blocks collapse.
    let fittedHeight = height ?? UIHostingController(rootView: content)
        .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    let layout = SwiftUISnapshotLayout.fixed(width: width, height: fittedHeight.rounded(.up))

    for style in [UIUserInterfaceStyle.light, .dark] {
        let traits = UITraitCollection { traits in
            traits.userInterfaceStyle = style
            traits.preferredContentSizeCategory = UIContentSizeCategory(dynamicType)
            traits.displayScale = 3
        }
        let image = snapshotting(for: content, layout: layout, traits: traits)
        SnapshotTesting.assertSnapshot(
            of: content,
            as: image,
            named: style == .dark ? "dark" : "light",
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

/// Takes the view only to name its type.
@MainActor
private func snapshotting<V: View>(for view: V, layout: SwiftUISnapshotLayout, traits: UITraitCollection) -> Snapshotting<V, UIImage> {
    .image(drawHierarchyInKeyWindow: false, precision: 1, perceptualPrecision: 0.98, layout: layout, traits: traits)
}
