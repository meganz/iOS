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
    
    public var cardinal: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter.string(from: NSNumber(value: self))
    }
}

// MARK: - TimeInterval

extension Int {
    public var seconds: TimeInterval { TimeInterval(self) }
    public var minutes: TimeInterval { seconds * 60 }
    public var hours: TimeInterval { minutes * 60 }
    public var days: TimeInterval { hours * 24 }
}

extension Int {
    public func toGBString() -> String {
        let bytes: Int64 = Int64(self * 1024 * 1024 * 1024)
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary)
    }
}

extension Int64 {
    public func bytesToGigabytes() -> Int {
        let bytesInGB: Double = 1024 * 1024 * 1024  // 1 GB in bytes
        let gigabytes = Double(self) / bytesInGB
        return Int(gigabytes)
    }
}
