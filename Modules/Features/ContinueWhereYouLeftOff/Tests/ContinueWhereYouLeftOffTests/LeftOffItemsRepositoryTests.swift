import ContinueWhereYouLeftOff
import ContinueWhereYouLeftOffMock
import Foundation
import MEGADomain
import Testing

@Suite("LeftOffItemsRepository")
struct LeftOffItemsRepositoryTests {

    private func item(_ handle: HandleEntity) -> LeftOffItemEntity {
        LeftOffItemEntity(handle: handle, name: "n\(handle)", lastAccessed: Date())
    }

    @Test("fetchItems forwards the sort key, direction and limit to the store")
    func fetchItemsForwardsSorting() async throws {
        let store = MockLeftOffItemsStore()
        let sut = LeftOffItemsRepository(store: store)

        _ = try await sut.fetchItems(sortedBy: .name, ascending: true, limit: 9)

        #expect(store.lastSortKey == .name)
        #expect(store.lastAscending == true)
        #expect(store.lastLimit == 9)
    }

    @Test("remove maps items to their handles for the store")
    func removeMapsToHandles() async throws {
        let store = MockLeftOffItemsStore()
        let sut = LeftOffItemsRepository(store: store)

        try await sut.remove([item(1), item(2)])

        #expect(store.removedHandles == [[1, 2]])
    }

    @Test("a raw store error maps to persistenceFailure")
    func mapsRawErrorToPersistenceFailure() async {
        struct SomeError: Error {}
        let store = MockLeftOffItemsStore(errorToThrow: SomeError())
        let sut = LeftOffItemsRepository(store: store)

        await #expect(throws: LeftOffItemErrorEntity.persistenceFailure) {
            try await sut.fetchItems(sortedBy: .lastAccessed, ascending: false, limit: 50)
        }
    }

    @Test("a cancellation maps to cancelled")
    func mapsCancellationToCancelled() async {
        let store = MockLeftOffItemsStore(errorToThrow: CancellationError())
        let sut = LeftOffItemsRepository(store: store)

        await #expect(throws: LeftOffItemErrorEntity.cancelled) {
            try await sut.fetchItems(sortedBy: .lastAccessed, ascending: false, limit: 50)
        }
    }

    @Test("record forwards to the store")
    func recordForwards() async throws {
        let store = MockLeftOffItemsStore()
        let sut = LeftOffItemsRepository(store: store)
        let recorded = item(5)

        try await sut.record(recorded)

        #expect(store.recordedItems == [recorded])
    }

    @Test("clearHistory forwards to the store")
    func clearHistoryForwards() async throws {
        let store = MockLeftOffItemsStore()
        let sut = LeftOffItemsRepository(store: store)

        try await sut.clearHistory()

        #expect(store.clearHistoryCallCount == 1)
    }
}
