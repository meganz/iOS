
import WidgetKit
import SwiftUI
import Firebase

@main
struct MEGAWidgetsBundle: SwiftUI.WidgetBundle {
    init() {
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
