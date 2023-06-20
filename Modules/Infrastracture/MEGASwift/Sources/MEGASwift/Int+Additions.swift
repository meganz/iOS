import Foundation

extension Int {
    public func string(
        allowedUnits: NSCalendar.Unit,
        unitStyle: DateComponentsFormatter.UnitsStyle = .full
    ) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = unitStyle
        return formatter.string(from: TimeInterval(self))
    }
    
    public static func random() -> Int {
        Int.random(in: Int.min...Int.max)
    }
}

// MARK: - TimeInterval

extension Int {
    public var seconds: TimeInterval { TimeInterval(self) }
    public var minutes: TimeInterval { seconds * 60 }
    public var hours: TimeInterval { minutes * 60 }
    public var days: TimeInterval { hours * 24 }
}
