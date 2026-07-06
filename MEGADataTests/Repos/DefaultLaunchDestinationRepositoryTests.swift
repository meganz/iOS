@testable import MEGA
import MEGADomain
import Testing

@Suite("DefaultLaunchDestinationRepositoryTests")
struct DefaultLaunchDestinationRepositoryTests {

    // MARK: - rawValue

    @Test("rawValue matches the legacy tab manager strings")
    func rawValue_matchesLegacyTabManagerStrings() {
        let expected: [LaunchDestinationEntity: String] = [
            .home: "home",
            .drive: "cloudDrive",
            .media: "cameraUploads",
            .chat: "chat",
            .sharedItems: "sharedItems",
            .favourites: "favourites",
            .offline: "offline"
        ]
        let sut = makeSUT()
        for (destination, rawValue) in expected {
            #expect(sut.rawValue(for: destination) == rawValue)
        }
    }

    // MARK: - destination

    @Test("destination round-trips every case")
    func destination_forEachRawValue_returnsMatchingDestination() {
        let sut = makeSUT()
        for destination in LaunchDestinationEntity.allCases {
            #expect(sut.destination(for: sut.rawValue(for: destination)) == destination)
        }
    }

    @Test("destination for the legacy cloudDrive string returns drive")
    func destination_forLegacyCloudDriveString_returnsDrive() {
        #expect(makeSUT().destination(for: "cloudDrive") == .drive)
    }

    @Test("destination for an unknown raw value returns nil")
    func destination_forUnknownRawValue_returnsNil() {
        #expect(makeSUT().destination(for: "not-a-real-tab") == nil)
    }

    // MARK: - Helpers

    private func makeSUT() -> DefaultLaunchDestinationRepository {
        DefaultLaunchDestinationRepository()
    }
}
