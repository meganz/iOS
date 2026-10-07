import MEGADesignToken
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

/// Records one light and one dark image of `view` shown in a real window.
/// Use it for content that fills in after the first frame, for example a list that loads its rows in a task.
/// The image is taken once `isReady` returns true for the window. It is polled every 10 ms, with no fixed wait.
/// The images go to `__Snapshots__/<test file name>/` next to the calling test file.
@MainActor
public func assertHostedSnapshot(
    of view: some View,
    width: CGFloat = 402,
    height: CGFloat,
    dynamicType: DynamicTypeSize = .large,
    layoutDirection: LayoutDirection = .leftToRight,
    timeout: Duration = .seconds(30),
    isReady: @MainActor (UIWindow) -> Bool,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) async {
    let sourceLocation = SourceLocation(
        fileID: String(describing: fileID),
        filePath: String(describing: filePath),
        line: Int(line),
        column: Int(column)
    )
    guard checkSnapshotDevice(sourceLocation: sourceLocation) else { return }
    UIView.setAnimationsEnabled(false)

    let content = view
        .frame(width: width, height: height, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .environment(\.locale, Locale(identifier: "en_US"))
        .environment(\.layoutDirection, layoutDirection)
        .environment(\.dynamicTypeSize, dynamicType)
        .transaction { $0.animation = nil }

    for style in [UIUserInterfaceStyle.light, .dark] {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: content)
        window.makeKeyAndVisible()
        defer {
            window.rootViewController = nil
            window.isHidden = true
        }
        let deadline = ContinuousClock.now + timeout
        while !isReady(window) {
            guard ContinuousClock.now < deadline, (try? await Task.sleep(for: .milliseconds(10))) != nil else {
                Issue.record("The view was not ready after \(timeout).", sourceLocation: sourceLocation)
                return
            }
        }
        window.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        SnapshotTesting.assertSnapshot(
            of: image,
            as: .image(precision: 1, perceptualPrecision: 0.98, scale: 3),
            named: style == .dark ? "dark" : "light",
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}
