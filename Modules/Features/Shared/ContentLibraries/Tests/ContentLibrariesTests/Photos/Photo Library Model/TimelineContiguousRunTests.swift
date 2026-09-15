@testable import ContentLibraries
import Foundation
import MEGADomain
import Testing

@Suite("The contiguous run of real nodes handed to a paginated photo browser")
struct TimelineContiguousRunTests {

    @Test("Stops at the placeholder on either side")
    func stopsAtPlaceholders() {
        // [ph, 1, 2, 3, ph, 4]
        let photos = [placeholder(0), real(1), real(2), real(3), placeholder(1), real(4)]

        let run = photos.contiguousRealRun(around: 2, radius: 100)

        #expect(run?.nodes.map(\.handle) == [1, 2, 3])
        #expect(run?.startIndex == 1)
    }

    @Test("Is clamped to the radius when nothing interrupts it")
    func clampedToRadius() {
        let photos = (1...101).map(real)

        let run = photos.contiguousRealRun(around: 50, radius: 10)

        #expect(run?.nodes.count == 21)
        #expect(run?.startIndex == 40)
        #expect(run?.nodes.first?.handle == 41)
        #expect(run?.nodes.last?.handle == 61)
    }

    @Test("Is cut by the radius before it reaches a placeholder")
    func radiusCutsFirst() {
        // The placeholder at 0 is further away than the radius reaches.
        let photos = [placeholder(0)] + (1...20).map(real)

        let run = photos.contiguousRealRun(around: 10, radius: 3)

        #expect(run?.startIndex == 7)
        #expect(run?.nodes.count == 7)
    }

    @Test("Reaches the ends of the projection")
    func reachesTheEnds() {
        let photos = (1...5).map(real)

        let run = photos.contiguousRealRun(around: 0, radius: 100)

        #expect(run?.startIndex == 0)
        #expect(run?.nodes.count == 5)
    }

    @Test("Is nil for a placeholder, which has nothing to open")
    func placeholderHasNoRun() {
        let photos = [real(1), placeholder(0), real(2)]

        #expect(photos.contiguousRealRun(around: 1, radius: 100) == nil)
    }

    @Test("Is nil out of range")
    func outOfRange() {
        let photos = [real(1)]

        #expect(photos.contiguousRealRun(around: 1, radius: 100) == nil)
        #expect(photos.contiguousRealRun(around: -1, radius: 100) == nil)
    }

    // MARK: - Helpers

    private func real(_ handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "node-\(handle)", handle: handle)
    }

    private func placeholder(_ offset: UInt64) -> NodeEntity {
        .timelinePlaceholder(offset: offset, date: Date())
    }
}
