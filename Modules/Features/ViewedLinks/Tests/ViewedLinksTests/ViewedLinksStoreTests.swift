import Foundation
import MEGADomain
import SwiftData
import Testing
@testable import ViewedLinks

@Suite("ViewedLinksStore")
struct ViewedLinksStoreTests {
    private struct TestError: Error {}

    private func makeStore(maxEntries: Int = 100) -> ViewedLinksStore {
        ViewedLinksStore(inMemory: true, maxEntries: maxEntries)
    }

    private func makeLink(
        handle: HandleEntity,
        name: String = "file.pdf",
        isFolder: Bool = false,
        lastAccessed: Date = Date(timeIntervalSince1970: 0)
    ) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(handle: handle, linkURL: url, name: name, isFolder: isFolder, hasThumbnail: false, lastAccessed: lastAccessed)
    }

    @Test("record then fetch returns the stored link")
    func recordThenFetch() async throws {
        let store = makeStore()
        try await store.record(makeLink(handle: 7, name: "a.pdf"))

        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.count == 1)
        #expect(all.first?.handle == 7)
        #expect(all.first?.name == "a.pdf")
    }

    @Test("re-recording the same handle keeps one row and updates fields (dedup upsert)")
    func dedupUpsertByHandle() async throws {
        let store = makeStore()
        try await store.record(makeLink(handle: 7, name: "old.pdf", lastAccessed: Date(timeIntervalSince1970: 1)))
        try await store.record(makeLink(handle: 7, name: "new.pdf", lastAccessed: Date(timeIntervalSince1970: 2)))

        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.count == 1)
        #expect(all.first?.name == "new.pdf")
    }

    @Test("sort by name honours ascending / descending")
    func sortByName() async throws {
        let store = makeStore()
        try await store.record(makeLink(handle: 1, name: "banana"))
        try await store.record(makeLink(handle: 2, name: "apple"))

        let asc = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(asc.map(\.name) == ["apple", "banana"])
        let desc = try await store.viewedLinks(sortedBy: .name, ascending: false)
        #expect(desc.map(\.name) == ["banana", "apple"])
    }

    @Test("sort by lastAccessed honours ascending / descending")
    func sortByLastAccessed() async throws {
        let store = makeStore()
        try await store.record(makeLink(handle: 1, name: "old", lastAccessed: Date(timeIntervalSince1970: 10)))
        try await store.record(makeLink(handle: 2, name: "new", lastAccessed: Date(timeIntervalSince1970: 20)))

        let asc = try await store.viewedLinks(sortedBy: .lastAccessed, ascending: true)
        #expect(asc.map(\.handle) == [1, 2])
        let desc = try await store.viewedLinks(sortedBy: .lastAccessed, ascending: false)
        #expect(desc.map(\.handle) == [2, 1])
    }

    @Test("topViewedLinks returns the N most recent by lastAccessed desc")
    func topViewedLinksLimit() async throws {
        let store = makeStore()
        for i in 1...6 {
            try await store.record(makeLink(handle: HandleEntity(i), name: "f\(i)", lastAccessed: Date(timeIntervalSince1970: TimeInterval(i))))
        }

        let top = try await store.topViewedLinks(limit: 4)
        #expect(top.count == 4)
        #expect(top.map(\.handle) == [6, 5, 4, 3])
    }

    @Test("topViewedLinks with a non-positive limit returns nothing")
    func topViewedLinksNonPositiveLimit() async throws {
        let store = makeStore()
        try await store.record(makeLink(handle: 1))

        let none = try await store.topViewedLinks(limit: 0)
        #expect(none.isEmpty)
    }

    @Test("remove deletes the given links")
    func removeLinks() async throws {
        let store = makeStore()
        let a = try makeLink(handle: 1)
        let b = try makeLink(handle: 2)
        try await store.record(a)
        try await store.record(b)

        try await store.remove([a])
        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.map(\.handle) == [2])
    }

    @Test("removeUnavailable deletes by URL")
    func removeUnavailableByURL() async throws {
        let store = makeStore()
        let link = try makeLink(handle: 1)
        try await store.record(link)

        try await store.removeUnavailable(linkURL: link.linkURL)
        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.isEmpty)
    }

    @Test("clearHistory removes everything")
    func clearHistory() async throws {
        let store = makeStore()
        try await store.record(makeLink(handle: 1))
        try await store.record(makeLink(handle: 2))

        try await store.clearHistory()
        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.isEmpty)
    }

    @Test("high-bit UInt64 handle round-trips through Int64 storage")
    func handleBitPatternRoundTrip() async throws {
        let store = makeStore()
        let handle: HandleEntity = 0xFFFF_FFFF_FFFF_FFF0
        try await store.record(makeLink(handle: handle, name: "big"))

        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.first?.handle == handle)
    }

    @Test("name sort reproduces Foundation localizedStandardCompare ordering")
    func localizedStandardSortParity() async throws {
        let store = makeStore()
        let names = ["file10", "File2", "file1", "apple", "Banana"]
        for (index, name) in names.enumerated() {
            try await store.record(makeLink(handle: HandleEntity(index + 1), name: name))
        }

        let sorted = try await store.viewedLinks(sortedBy: .name, ascending: true)
        let expected = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        #expect(sorted.map(\.name) == expected)
    }

    @Test("record evicts rows beyond maxEntries, keeping the newest")
    func recordEvictsBeyondMaxEntries() async throws {
        let store = makeStore(maxEntries: 3)
        for i in 1...5 {
            try await store.record(makeLink(handle: HandleEntity(i), name: "f\(i)", lastAccessed: Date(timeIntervalSince1970: TimeInterval(i))))
        }

        let all = try await store.viewedLinks(sortedBy: .lastAccessed, ascending: false)
        #expect(all.map(\.handle) == [5, 4, 3])
    }

    @Test("re-recording an existing handle at the cap evicts nothing")
    func reRecordAtCapEvictsNothing() async throws {
        let store = makeStore(maxEntries: 3)
        for i in 1...3 {
            try await store.record(makeLink(handle: HandleEntity(i), name: "f\(i)", lastAccessed: Date(timeIntervalSince1970: TimeInterval(i))))
        }
        try await store.record(makeLink(handle: 2, name: "f2-new", lastAccessed: Date(timeIntervalSince1970: 100)))

        let all = try await store.viewedLinks(sortedBy: .lastAccessed, ascending: true)
        #expect(all.count == 3)
        #expect(Set(all.map(\.handle)) == [1, 2, 3])
    }

    @Test("change signal emits on a persisted mutation")
    func changeSignalEmitsOnMutation() async throws {
        let store = makeStore()
        let signal = store.changesSignalSequence()

        let received = Task { () -> Bool in
            for await _ in signal { return true }
            return false
        }
        // The observer registers on iteration, so give it a head start before mutating.
        try await Task.sleep(for: .milliseconds(50))
        try await store.record(makeLink(handle: 1))

        #expect(await received.value)
    }

    @Test("a thrown write rolls back and does not poison the context")
    func failedWriteRollsBack() async throws {
        let store = makeStore()

        await #expect(throws: TestError.self) {
            try await store.write { context in
                context.insert(ViewedLinkModel(
                    handle: 1,
                    linkURL: "https://mega.nz/file/1#key",
                    name: "pending",
                    isFolder: false,
                    hasThumbnail: false,
                    lastAccessed: Date(timeIntervalSince1970: 0)
                ))
                throw TestError()
            }
        }

        try await store.record(makeLink(handle: 2, name: "ok"))
        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)
        #expect(all.map(\.handle) == [2])
    }
}
