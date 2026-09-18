import ContentLibraries
import Foundation
@testable import MEGA
import MEGADomain
import Testing

@Suite("TimelineProjection Tests")
struct TimelineProjectionTests {
    private static let firstDay = Date(timeIntervalSince1970: 1_660_780_800)  // 2022-08-18T00:00:00Z
    private static let secondDay = Date(timeIntervalSince1970: 1_658_102_400) // 2022-07-18T00:00:00Z

    /// Two day buckets of 2 and 3 slots: flat indices 0...1 sit in `2022-08-18`, 2...4 in `2022-07-18`.
    private static let sections: [MediaDateSectionEntity] = [
        .init(groupId: "2022-08-18", startDate: firstDay, endDate: firstDay, count: 2),
        .init(groupId: "2022-07-18", startDate: secondDay, endDate: secondDay, count: 3)
    ]

    /// A skeleton with `replacements` spliced in, indexed the way a splice indexes them.
    private static func makeProjection(
        hydrating replacements: [Int: NodeEntity] = [:]
    ) -> TimelineProjection {
        let skeleton = TimelineProjection(
            library: PhotoLibrary.skeleton(from: sections), sections: sections, hydratedCoordinates: [:])
        var coordinates: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]
        for (index, node) in replacements {
            guard let anchor = skeleton.sectionAnchor(forFlatIndex: index) else { continue }
            coordinates[node.handle] = .init(
                groupId: anchor.section.groupId, localOffset: anchor.localOffset)
        }
        return TimelineProjection(
            library: skeleton.library.replacingPhotos(at: replacements),
            sections: sections,
            hydratedCoordinates: coordinates)
    }

    // MARK: - Slots

    @Test("The slot count is the bucket counts summed")
    func itemCount() {
        #expect(Self.makeProjection().itemCount == 5)
    }

    @Test("Every flat index resolves to the node the flattened library holds there")
    func nodeAtEveryIndex() {
        let projection = Self.makeProjection(hydrating: [3: NodeEntity(handle: 99)])
        let flattened = projection.library.allPhotos

        for index in flattened.indices {
            #expect(projection.node(at: index) == flattened[index])
        }
        #expect(projection.node(at: -1) == nil)
        #expect(projection.node(at: flattened.count) == nil)
    }

    @Test("A slot is a placeholder until it is hydrated; a slot outside the tree is neither")
    func placeholderAndHydratedSlots() {
        let node = NodeEntity(handle: 99)
        let projection = Self.makeProjection(hydrating: [3: node])

        #expect(projection.isPlaceholder(at: 2))
        #expect(projection.isPlaceholder(at: 3) == false)
        #expect(projection.isPlaceholder(at: -1) == false)
        #expect(projection.isPlaceholder(at: 5) == false)

        #expect(projection.hydratedNode(at: 3) == node)
        #expect(projection.hydratedNode(at: 2) == nil)
        #expect(projection.hydratedNode(at: 5) == nil)
    }

    // MARK: - Buckets

    @Test("A bucket's base is where the buckets before it end")
    func bucketBases() {
        let projection = Self.makeProjection()

        #expect(projection.base(ofGroupId: "2022-08-18") == 0)
        #expect(projection.base(ofGroupId: "2022-07-18") == 2)
        #expect(projection.base(ofGroupId: "2022-06-18") == nil)
        #expect(projection.containsSection(groupId: "2022-07-18"))
        #expect(projection.containsSection(groupId: "2022-06-18") == false)
    }

    @Test("A flat index resolves to its section and its offset within it")
    func sectionAnchors() {
        let projection = Self.makeProjection()
        let expected = [
            ("2022-08-18", 0), ("2022-08-18", 1),
            ("2022-07-18", 0), ("2022-07-18", 1), ("2022-07-18", 2)
        ]

        for (index, expectation) in expected.enumerated() {
            let anchor = projection.sectionAnchor(forFlatIndex: index)
            #expect(anchor?.section.groupId == expectation.0)
            #expect(anchor?.localOffset == expectation.1)
        }
        #expect(projection.sectionAnchor(forFlatIndex: 5)?.localOffset == nil)
        #expect(projection.sectionAnchor(forFlatIndex: -1)?.localOffset == nil)
    }

    @Test("A window depends on exactly the buckets it overlaps")
    func groupIdsSpanningAWindow() {
        let projection = Self.makeProjection()

        #expect(projection.groupIds(spanning: 0..<2) == ["2022-08-18"])
        #expect(projection.groupIds(spanning: 1..<3) == ["2022-08-18", "2022-07-18"])
        #expect(projection.groupIds(spanning: 2..<5) == ["2022-07-18"])
        // Past the end — a stale range names no bucket, so nothing is captured against it.
        #expect(projection.groupIds(spanning: 5..<8) == [])
    }

    // MARK: - Handles

    @Test("A hydrated node is found by handle, addressed by the bucket holding it")
    func handleLookup() {
        let projection = Self.makeProjection(hydrating: [3: NodeEntity(handle: 99)])

        #expect(projection.hydratedCoordinates[99] == .init(groupId: "2022-07-18", localOffset: 1))
        #expect(projection.flatIndex(ofHandle: 99) == 3)
        #expect(projection.flatIndex(ofHandle: 1234) == nil)
    }

    @Test("Each hydrated node keeps the offset it has within its own bucket")
    func coordinatesAcrossBuckets() {
        let projection = Self.makeProjection(hydrating: [
            0: NodeEntity(handle: 10),
            1: NodeEntity(handle: 11),
            2: NodeEntity(handle: 20),
            4: NodeEntity(handle: 22)
        ])

        #expect(projection.hydratedCoordinates[10] == .init(groupId: "2022-08-18", localOffset: 0))
        #expect(projection.hydratedCoordinates[11] == .init(groupId: "2022-08-18", localOffset: 1))
        #expect(projection.hydratedCoordinates[20] == .init(groupId: "2022-07-18", localOffset: 0))
        #expect(projection.hydratedCoordinates[22] == .init(groupId: "2022-07-18", localOffset: 2))
        #expect(projection.flatIndex(ofHandle: 22) == 4)
    }

    /// The index is the splice's duplicate guard, so a synthetic handle in it would make a fetched
    /// node look already present and drop the fill.
    @Test("Placeholder slots are not indexed, so a synthetic handle never looks occupied")
    func placeholderHandlesAreNotIndexed() throws {
        let projection = Self.makeProjection(hydrating: [3: NodeEntity(handle: 99)])
        let placeholder = try #require(projection.node(at: 0))

        #expect(placeholder.isTimelinePlaceholder)
        #expect(projection.hydratedCoordinates.count == 1)
        #expect(projection.flatIndex(ofHandle: placeholder.handle) == nil)
    }

    /// Why the index is keyed by bucket, not by flat position: it is carried across a reshape
    /// unchanged and read back against whatever layout it is handed to.
    @Test("A bucket growing above a node moves the node with it, from the same coordinate")
    func coordinatesResolveAgainstTheLayoutTheyAreReadIn() {
        // The first bucket has grown from 2 slots to 4; the node kept its offset in the second.
        let grown: [MediaDateSectionEntity] = [
            .init(groupId: "2022-08-18", startDate: Self.firstDay, endDate: Self.firstDay, count: 4),
            .init(groupId: "2022-07-18", startDate: Self.secondDay, endDate: Self.secondDay, count: 3)
        ]
        let projection = TimelineProjection(
            library: PhotoLibrary.skeleton(from: grown).replacingPhotos(at: [5: NodeEntity(handle: 99)]),
            sections: grown,
            hydratedCoordinates: [99: .init(groupId: "2022-07-18", localOffset: 1)])

        #expect(projection.flatIndex(ofHandle: 99) == 5)
    }

    // MARK: - Empty layout

    @Test("An empty layout answers nothing rather than trapping")
    func emptyLayout() {
        let projection = TimelineProjection(library: PhotoLibrary(), sections: [], hydratedCoordinates: [:])

        #expect(projection.itemCount == 0)
        #expect(projection.node(at: 0) == nil)
        #expect(projection.isPlaceholder(at: 0) == false)
        #expect(projection.base(ofGroupId: "2022-08-18") == nil)
        #expect(projection.sectionAnchor(forFlatIndex: 0)?.localOffset == nil)
        #expect(projection.groupIds(spanning: 0..<10) == [])
        #expect(projection.flatIndex(ofHandle: 1) == nil)
    }
}
