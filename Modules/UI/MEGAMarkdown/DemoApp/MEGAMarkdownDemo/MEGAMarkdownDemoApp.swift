import MEGAFoundation
import SwiftUI

@main
struct MEGAMarkdownDemoApp: App {
    init() {
        MEGALog.register(loggers: [ConsoleLogger()])
    }

    var body: some Scene {
        WindowGroup {
            // scripts/capture.sh starts the capture mode with launch arguments.
            if let capture = CaptureConfig.fromLaunchArguments() {
                CaptureView(config: capture)
            } else {
                RootView()
            }
        }
    }
}
