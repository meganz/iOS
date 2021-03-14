
import WidgetKit
import SwiftUI
import Firebase

@main
struct MEGAWidgetsBundle: SwiftUI.WidgetBundle {
    init() {
        FirebaseApp.configure()
        
        NSSetUncaughtExceptionHandler { (exception) in
            MEGALogError("Exception name: \(exception.name)\nreason: \(String(describing: exception.reason))\nuser info: \(String(describing: exception.userInfo))\n")
            MEGALogError("Stack trace: \(exception.callStackSymbols)")
        }
        
        setupLogging()
    }
    
    @WidgetBundleBuilder
    var body: some Widget {
        ShortcutsWidget()
        FavouritesQuickAccessWidget()
        RecentsQuickAccessWidget()
        OfflineQuickAccessWidget()
    }
    
    private func setupLogging() {
#if DEBUG
        MEGASdk.setLogLevel(.max)
        MEGAChatSdk.setCatchException(false)
#else
        MEGASdk.setLogLevel(.fatal)
#endif
        MEGASdk.setLogToConsole(true)
        
        guard let sharedUserDefaults = UserDefaults.init(suiteName: MEGAGroupIdentifier) else {
            return
        }
        
        if sharedUserDefaults.bool(forKey: "logging") {
            guard let logsFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionLogsFolder) else {
                return
            }
            if !FileManager.default.fileExists(atPath: logsFolderURL.path) {
                do {
                    try FileManager.default.createDirectory(atPath: logsFolderURL.path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    MEGALogError("Error creating logs directory: \(logsFolderURL.path)")
                    return
                }
            }
            let logsPath = logsFolderURL.appendingPathComponent("MEGAiOS.Widget.log").path
            MEGALogger.shared()?.startLogging(toFile: logsPath)
        }
    }
}
