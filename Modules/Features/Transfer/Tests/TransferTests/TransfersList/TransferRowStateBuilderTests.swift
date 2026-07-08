import Foundation
import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@MainActor
@Suite("TransferRowStateBuilder")
struct TransferRowStateBuilderTests {

    @Test(arguments: [TransfersTab.active, .failed])
    func plainTabsSnapshotWithoutLocationOrFinishDate(tab: TransfersTab) async {
        let resolver = SpyLocationResolver()
        let provider = SpyFinishDateProvider()
        let sut = makeSUT(tab: tab, resolver: resolver, provider: provider)

        let states = await sut.snapshotStates(for: [.init(type: .download, tag: 1, state: .active)])

        #expect(states.map(\.id) == [1])
        #expect(states[0].location == nil)
        #expect(states[0].finishDate == nil)
        #expect(states[0].canViewInFolder)
        #expect(resolver.resolvedTags.isEmpty)
        #expect(provider.recordedTags.isEmpty)
    }

    @Test func completedSnapshotReadsRecordedFinishDateAndLocation() async {
        let resolver = SpyLocationResolver(location: "/cloud/folder")
        let provider = SpyFinishDateProvider()
        let finishDate = Date(timeIntervalSince1970: 100)
        provider.storedDates[1] = finishDate
        let sut = makeSUT(tab: .completed, resolver: resolver, provider: provider)

        let states = await sut.snapshotStates(for: [.init(type: .download, tag: 1, state: .complete)])

        #expect(states[0].location == "/cloud/folder")
        #expect(states[0].finishDate == finishDate)
        // Snapshot is a read of the already-captured date, never a stamp.
        #expect(provider.recordedTags.isEmpty)
    }

    @Test func completedFinishStateStampsTheFinishDate() async {
        let provider = SpyFinishDateProvider()
        let sut = makeSUT(tab: .completed, provider: provider)

        let state = await sut.finishState(for: .init(type: .download, tag: 1, state: .complete))

        #expect(provider.recordedTags == [1])
        #expect(state.finishDate == provider.storedDates[1])
    }

    @Test func failedFinishStateIsAPlainTransform() async {
        let resolver = SpyLocationResolver()
        let provider = SpyFinishDateProvider()
        let sut = makeSUT(tab: .failed, resolver: resolver, provider: provider)

        let state = await sut.finishState(for: .init(type: .upload, tag: 2, state: .failed))

        #expect(state.location == nil)
        #expect(state.finishDate == nil)
        #expect(resolver.resolvedTags.isEmpty)
        #expect(provider.recordedTags.isEmpty)
    }

    @Test func completedUploadLocationsAreCachedPerDestinationFolder() async {
        let resolver = SpyLocationResolver(location: "/cloud/folder")
        let sut = makeSUT(tab: .completed, resolver: resolver)

        let states = await sut.snapshotStates(for: [
            .init(type: .upload, parentHandle: 7, tag: 1, state: .complete),
            .init(type: .upload, parentHandle: 7, tag: 2, state: .complete),
            .init(type: .upload, parentHandle: 8, tag: 3, state: .complete)
        ])

        #expect(states.map(\.location) == ["/cloud/folder", "/cloud/folder", "/cloud/folder"])
        // One lookup per destination folder, not per row.
        #expect(resolver.resolvedTags == [1, 3])
    }

    @Test func completedUploadNilLocationIsCachedAsNegativeResult() async {
        let resolver = SpyLocationResolver(location: nil)
        let sut = makeSUT(tab: .completed, resolver: resolver)

        let states = await sut.snapshotStates(for: [
            .init(type: .upload, parentHandle: 7, tag: 1, state: .complete),
            .init(type: .upload, parentHandle: 7, tag: 2, state: .complete)
        ])

        #expect(states.map(\.location) == [nil, nil])
        #expect(resolver.resolvedTags == [1])
    }

    @Test func completedDownloadLocationsAreNotCached() async {
        let resolver = SpyLocationResolver(location: "/local/folder")
        let sut = makeSUT(tab: .completed, resolver: resolver)

        let states = await sut.snapshotStates(for: [
            .init(type: .download, tag: 1, state: .complete),
            .init(type: .download, tag: 2, state: .complete)
        ])

        #expect(states.map(\.location) == ["/local/folder", "/local/folder"])
        #expect(resolver.resolvedTags == [1, 2])
    }

    @Test func savedToPhotosDownloadCannotBeViewedInFolder() async {
        let sut = makeSUT(tab: .completed)

        let state = await sut.finishState(
            for: .init(type: .download, tag: 1, appData: ">SaveInPhotosApp", state: .complete)
        )

        #expect(!state.canViewInFolder)
    }

    // MARK: - Helpers

    private func makeSUT(
        tab: TransfersTab,
        resolver: SpyLocationResolver = SpyLocationResolver(),
        provider: SpyFinishDateProvider = SpyFinishDateProvider()
    ) -> TransferRowStateBuilder {
        TransferRowStateBuilder(tab: tab, locationResolver: resolver, finishDateProvider: provider)
    }
}

private final class SpyLocationResolver: TransferLocationResolving, @unchecked Sendable {
    private(set) var resolvedTags: [Int] = []
    private let location: String?

    init(location: String? = nil) {
        self.location = location
    }

    func location(for entity: TransferEntity) async -> String? {
        resolvedTags.append(entity.tag)
        return location
    }
}

private final class SpyFinishDateProvider: TransferFinishDateProviding, @unchecked Sendable {
    var storedDates: [Int: Date] = [:]
    private(set) var recordedTags: [Int] = []

    func finishDate(forTag tag: Int) -> Date? {
        storedDates[tag]
    }

    func recordIfAbsent(tag: Int, date: Date) -> Date {
        recordedTags.append(tag)
        if let existing = storedDates[tag] {
            return existing
        }
        storedDates[tag] = date
        return date
    }

    func removeDates(forTags tags: Set<Int>) {}
}
