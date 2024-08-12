import Foundation
import WidgetKit

protocol WidgetCentreProtocol {
    /// Reloads the timelines for all widgets of a particular kind.
    /// - Parameter kind: A string that identifies the widget and matches the
    ///   value you used when you created the widget's configuration.
    func reloadTimelines(ofKind kind: String)

    /// Reloads the timelines for all configured widgets belonging to the
    /// containing app.
    func reloadAllTimelines()
}

extension WidgetCenter: WidgetCentreProtocol { }
