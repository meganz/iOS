import Foundation

extension Double {
    var percent: String? {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.multiplier = 100
        percentFormatter.minimumFractionDigits = 1
        percentFormatter.maximumFractionDigits = 2
        percentFormatter.locale = Locale(identifier: "en_US")
        return percentFormatter.string(for: self)
    }
}
