import SwiftUI
import UIKit

public extension View {
    func toUIView(hostingViewBackgroundColor: UIColor = .clear) -> UIView {
        let hostingController = UIHostingController(rootView: self)
        hostingController.view.backgroundColor = hostingViewBackgroundColor
        return hostingController.view
    }
}
