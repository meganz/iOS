import Foundation

extension Duration {
    /// The duration expressed in seconds, keeping the sub-second part that `components.seconds` truncates away
    var timeInterval: TimeInterval {
        self / .seconds(1)
    }
}
