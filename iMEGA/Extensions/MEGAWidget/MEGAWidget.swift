
import Firebase
import SwiftUI
import WidgetKit

@main
struct MEGAWidgetsBundle: SwiftUI.WidgetBundle {
    init() {
        AppEnvironmentConfigurator.configAppEnvironment()
        FirebaseApp.configure()
        UncaughtExceptionHandler.registerHandler()
    }
    
    @WidgetBundleBuilder
    var body: some Widget {
        ShortcutsWidget()
        FavouritesQuickAccessWidget()
        RecentsQuickAccessWidget()
        OfflineQuickAccessWidget()
    }
}
