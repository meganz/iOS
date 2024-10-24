import SwiftUI
import WidgetKit

public extension Image {
    @ViewBuilder
    func applyAccentedDesaturatedRenderingMode() -> some View {
        if #available(iOS 18.0, *) {
            self.widgetAccentedRenderingMode(.accentedDesaturated)
        } else {
            self
        }
    }
}
