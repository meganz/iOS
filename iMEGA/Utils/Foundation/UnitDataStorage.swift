import Foundation

/// As of `UnitInformationStorage` is only available on iOS 13, so defining this class to backporting the unit for information data storage measuring.
@objc class UnitDataStorage: Dimension {
    static let bits = UnitDataStorage(symbol: "bit", converter: UnitConverterLinear(coefficient: 1))
    static let bytes = UnitDataStorage(symbol: "B", converter: UnitConverterLinear(coefficient: 8))
    static let kilobytes = UnitDataStorage(symbol: "KB", converter: UnitConverterLinear(coefficient: 8 * 1024))
    static let megabytes = UnitDataStorage(symbol: "MB", converter: UnitConverterLinear(coefficient: 8 * 1024 * 1024))
    static let gigabytes = UnitDataStorage(symbol: "GB", converter: UnitConverterLinear(coefficient: 8 * 1024 * 1024 * 1024))
    static let terabytes = UnitDataStorage(symbol: "TB", converter: UnitConverterLinear(coefficient: 8 * 1024 * 1024 * 1024 * 1024))
    static let petabytes = UnitDataStorage(symbol: "PB", converter: UnitConverterLinear(coefficient: 8 * 1024 * 1024 * 1024 * 1024 * 1024))

    override class func baseUnit() -> Self {
        Self(symbol: "bit")
    }
}

extension Measurement where UnitType == UnitDataStorage {

    init<T>(value: T, unit: UnitType) where T: FixedWidthInteger {
        self.init(value: Double(value), unit: unit)
    }

    static func bytes<T>(of value: T) -> Self where T: FixedWidthInteger {
        Measurement(value: Double(value), unit: .bytes)
    }

    static func kilobytes<T>(of value: T) -> Self where T: FixedWidthInteger {
        Measurement(value: Double(value), unit: .kilobytes)
    }

    static func megabytes<T>(of value: T) -> Self where T: FixedWidthInteger {
        Measurement(value: Double(value), unit: .megabytes)
    }

    static func gigabytes<T>(of value: T) -> Self where T: FixedWidthInteger {
        Measurement(value: Double(value), unit: .gigabytes)
    }

    static func terabytes<T>(of value: T) -> Self where T: FixedWidthInteger {
        Measurement(value: Double(value), unit: .terabytes)
    }

    static func petabytes<T>(of value: T) -> Self where T: FixedWidthInteger {
        Measurement(value: Double(value), unit: .petabytes)
    }
}

extension Measurement where UnitType == UnitDataStorage {

    var valueNumber: NSNumber {
        NSNumber(value: value)
    }
}
