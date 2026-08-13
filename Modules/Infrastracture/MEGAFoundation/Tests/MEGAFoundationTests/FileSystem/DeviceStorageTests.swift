import Foundation
@testable import MEGAFoundation
import Testing

@Suite("DeviceStorage")
struct DeviceStorageTests {
    @Test("Reports the room left on the volume the app lives on")
    func reportsCapacityOfTheCurrentVolume() {
        #expect(DeviceStorage.current.availableCapacity() != nil)
    }

    @Test("Falls back to the raw free size when the volume cannot report its important usage capacity")
    func fallsBackToSystemFreeSize() {
        let sut = DeviceStorage(volumeURL: .unreachable, systemFreeSize: { _ in 4_096 })

        #expect(sut.availableCapacity() == 4_096)
    }

    @Test("Reports nothing when neither query can answer, so a reading can be told apart from a failure")
    func reportsNothingWhenTheVolumeCannotBeQueried() {
        let sut = DeviceStorage(volumeURL: .unreachable)

        #expect(sut.availableCapacity() == nil)
    }
}

private extension URL {
    /// Fails both queries: the resource values throw for a path that does not exist, and so does
    /// `statfs` behind `attributesOfFileSystem(forPath:)`.
    static let unreachable = URL(fileURLWithPath: "/this-path-does-not-exist")
}
