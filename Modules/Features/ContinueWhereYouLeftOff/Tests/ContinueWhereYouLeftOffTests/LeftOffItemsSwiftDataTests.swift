import Foundation
import MEGADomain
import SwiftData
import Testing
@testable import ContinueWhereYouLeftOff

@Suite("ContinueWhereYouLeftOff SwiftData", .serialized)
struct LeftOffItemsSwiftDataTests {
    @Suite("LeftOffItemsStore")
    struct LeftOffItemsStoreTests {
        private struct TestError: Error {}

        private func makeStore(maxEntries: Int = 100) -> LeftOffItemsStore {
            LeftOffItemsStore(inMemory: true, maxEntries: maxEntries)
        }

        private func makeItem(
            handle: HandleEntity,
            name: String = "file.mp4",
            lastAccessed: Date = Date(timeIntervalSince1970: 0)
        ) -> LeftOffItemEntity {
            LeftOffItemEntity(handle: handle, name: name, lastAccessed: lastAccessed)
        }

        @Test("record then fetch returns the stored item")
        func recordThenFetch() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 7, name: "a.mp4"))

            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.count == 1)
            #expect(all.first?.handle == 7)
            #expect(all.first?.name == "a.mp4")
        }

        @Test("re-recording the same handle keeps one row and updates fields (dedup upsert)")
        func dedupUpsertByHandle() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 7, name: "old.mp4", lastAccessed: Date(timeIntervalSince1970: 1)))
            try await store.record(makeItem(handle: 7, name: "new.mp4", lastAccessed: Date(timeIntervalSince1970: 2)))

            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.count == 1)
            #expect(all.first?.name == "new.mp4")
            #expect(all.first?.lastAccessed == Date(timeIntervalSince1970: 2))
        }

        @Test("sort by name honours ascending / descending")
        func sortByName() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 1, name: "banana"))
            try await store.record(makeItem(handle: 2, name: "apple"))

            let asc = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(asc.map(\.name) == ["apple", "banana"])
            let desc = try await store.fetchItems(sortedBy: .name, ascending: false, limit: 100)
            #expect(desc.map(\.name) == ["banana", "apple"])
        }

        @Test("sort by lastAccessed honours ascending / descending")
        func sortByLastAccessed() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 1, name: "old", lastAccessed: Date(timeIntervalSince1970: 10)))
            try await store.record(makeItem(handle: 2, name: "new", lastAccessed: Date(timeIntervalSince1970: 20)))

            let asc = try await store.fetchItems(sortedBy: .lastAccessed, ascending: true, limit: 100)
            #expect(asc.map(\.handle) == [1, 2])
            let desc = try await store.fetchItems(sortedBy: .lastAccessed, ascending: false, limit: 100)
            #expect(desc.map(\.handle) == [2, 1])
        }

        @Test("fetchItems returns the N most recent when sorted by lastAccessed desc")
        func fetchItemsLimit() async throws {
            let store = makeStore()
            for i in 1...6 {
                try await store.record(makeItem(handle: HandleEntity(i), name: "f\(i)", lastAccessed: Date(timeIntervalSince1970: TimeInterval(i))))
            }

            let top = try await store.fetchItems(sortedBy: .lastAccessed, ascending: false, limit: 4)
            #expect(top.count == 4)
            #expect(top.map(\.handle) == [6, 5, 4, 3])
        }

        @Test("fetchItems with a non-positive limit returns nothing")
        func fetchItemsNonPositiveLimit() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 1))

            let none = try await store.fetchItems(sortedBy: .lastAccessed, ascending: false, limit: 0)
            #expect(none.isEmpty)
        }

        @Test("remove deletes the given handles")
        func removeHandles() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 1))
            try await store.record(makeItem(handle: 2))

            try await store.remove(handles: [1])
            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.map(\.handle) == [2])
        }

        @Test("removeUnavailable deletes by handle")
        func removeUnavailableByHandle() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 1))

            try await store.removeUnavailable(handle: 1)
            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.isEmpty)
        }

        @Test("clearHistory removes everything")
        func clearHistory() async throws {
            let store = makeStore()
            try await store.record(makeItem(handle: 1))
            try await store.record(makeItem(handle: 2))

            try await store.clearHistory()
            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.isEmpty)
        }

        @Test("high-bit UInt64 handle round-trips through Int64 storage")
        func handleBitPatternRoundTrip() async throws {
            let store = makeStore()
            let handle: HandleEntity = 0xFFFF_FFFF_FFFF_FFF0
            try await store.record(makeItem(handle: handle, name: "big"))

            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.first?.handle == handle)
        }

        @Test("name sort reproduces Foundation localizedStandardCompare ordering")
        func localizedStandardSortParity() async throws {
            let store = makeStore()
            let names = ["file10", "File2", "file1", "apple", "Banana"]
            for (index, name) in names.enumerated() {
                try await store.record(makeItem(handle: HandleEntity(index + 1), name: name))
            }

            let sorted = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            let expected = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            #expect(sorted.map(\.name) == expected)
        }

        @Test("record evicts rows beyond maxEntries, keeping the newest")
        func recordEvictsBeyondMaxEntries() async throws {
            let store = makeStore(maxEntries: 3)
            for i in 1...5 {
                try await store.record(makeItem(handle: HandleEntity(i), name: "f\(i)", lastAccessed: Date(timeIntervalSince1970: TimeInterval(i))))
            }

            let all = try await store.fetchItems(sortedBy: .lastAccessed, ascending: false, limit: 100)
            #expect(all.map(\.handle) == [5, 4, 3])
        }

        @Test("re-recording an existing handle at the cap evicts nothing")
        func reRecordAtCapEvictsNothing() async throws {
            let store = makeStore(maxEntries: 3)
            for i in 1...3 {
                try await store.record(makeItem(handle: HandleEntity(i), name: "f\(i)", lastAccessed: Date(timeIntervalSince1970: TimeInterval(i))))
            }
            try await store.record(makeItem(handle: 2, name: "f2-new", lastAccessed: Date(timeIntervalSince1970: 100)))

            let all = try await store.fetchItems(sortedBy: .lastAccessed, ascending: true, limit: 100)
            #expect(all.count == 3)
            #expect(Set(all.map(\.handle)) == [1, 2, 3])
        }

        @Test("change signal emits on a persisted mutation")
        func changeSignalEmitsOnMutation() async throws {
            let store = makeStore()
            // Making the iterator registers the observer, so the write below cannot be missed.
            var iterator = store.changesSignalSequence().makeAsyncIterator()

            try await store.record(makeItem(handle: 1))

            #expect(await iterator.next() != nil)
        }

        @Test("a thrown write rolls back and does not poison the context")
        func failedWriteRollsBack() async throws {
            let store = makeStore()

            await #expect(throws: TestError.self) {
                try await store.write { context in
                    context.insert(LeftOffItemModel(
                        handle: 1,
                        name: "pending",
                        lastAccessed: Date(timeIntervalSince1970: 0)
                    ))
                    throw TestError()
                }
            }

            try await store.record(makeItem(handle: 2, name: "ok"))
            let all = try await store.fetchItems(sortedBy: .name, ascending: true, limit: 100)
            #expect(all.map(\.handle) == [2])
        }
    }
}
