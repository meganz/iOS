import Foundation
@testable import MEGAFoundation
import XCTest

final class UnitDataStorageTests: XCTestCase {
    func test_baseUnit_returnsBits() {
        XCTAssertEqual(UnitDataStorage.baseUnit().symbol, "bit", "baseUnit should return bits")
    }

    func test_measurementBytes_returnsSymbolB() {
        let measurement = Measurement.bytes(of: 1024)
        XCTAssertEqual(measurement.value, 1024.0, "Measurement.bytes should correctly store the value")
        XCTAssertEqual(measurement.unit.symbol, "B", "Measurement.bytes should correctly store the unit")
    }

    func test_measurementKilobytes_returnsSymbolKB() {
        let measurement = Measurement.kilobytes(of: 1)
        XCTAssertEqual(measurement.value, 1.0, "Measurement.kilobytes should correctly store the value")
        XCTAssertEqual(measurement.unit.symbol, "KB", "Measurement.kilobytes should correctly store the unit")
    }

    func test_measurementMegabytes_returnsSymbolMB() {
        let measurement = Measurement.megabytes(of: 1)
        XCTAssertEqual(measurement.value, 1.0, "Measurement.megabytes should correctly store the value")
        XCTAssertEqual(measurement.unit.symbol, "MB", "Measurement.megabytes should correctly store the unit")
    }

    func test_measurementGigabytes_returnsSymbolGB() {
        let measurement = Measurement.gigabytes(of: 1)
        XCTAssertEqual(measurement.value, 1.0, "Measurement.gigabytes should correctly store the value")
        XCTAssertEqual(measurement.unit.symbol, "GB", "Measurement.gigabytes should correctly store the unit")
    }

    func test_measurementTerabytes_returnsSymbolTB() {
        let measurement = Measurement.terabytes(of: 1)
        XCTAssertEqual(measurement.value, 1.0, "Measurement.terabytes should correctly store the value")
        XCTAssertEqual(measurement.unit.symbol, "TB", "Measurement.terabytes should correctly store the unit")
    }

    func test_measurementPetabytes_returnsSymbolPB() {
        let measurement = Measurement.petabytes(of: 1)
        XCTAssertEqual(measurement.value, 1.0, "Measurement.petabytes should correctly store the value")
        XCTAssertEqual(measurement.unit.symbol, "PB", "Measurement.petabytes should correctly store the unit")
    }
}
