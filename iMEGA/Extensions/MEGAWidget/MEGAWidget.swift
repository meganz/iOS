
import WidgetKit
import SwiftUI

@main
struct MEGAWidgetsBundle: SwiftUI.WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ShortcutsWidget()
    }
}
