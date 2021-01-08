
import WidgetKit
import SwiftUI
import Firebase

@main
struct MEGAWidgetsBundle: SwiftUI.WidgetBundle {
    init() {
        FirebaseApp.configure()
    }
    
    @WidgetBundleBuilder
    var body: some Widget {
        ShortcutsWidget()
    }
}
