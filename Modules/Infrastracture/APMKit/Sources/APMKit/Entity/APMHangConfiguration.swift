import Foundation

struct APMHangConfiguration: Sendable {
    static var defaultConfig: APMHangConfiguration {
        APMHangConfiguration(threshold: 1.0)
    }
    let threshold: TimeInterval
}
