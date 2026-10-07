@testable import ContinueWhereYouLeftOff
import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("LeftOffItemWidgetCardModel")
struct LeftOffItemCardModelTests {
    private func makeResolved(
        node: NodeEntity,
        isSensitive: Bool = false
    ) -> ResolvedLeftOffItemEntity {
        ResolvedLeftOffItemEntity(
            item: LeftOffItemEntity(handle: node.handle, name: node.name, lastAccessed: .now),
            node: node,
            isSensitive: isSensitive
        )
    }

    @Test("a video shows its duration")
    func videoShowsDuration() {
        let node = NodeEntity(name: "clip.mp4", handle: 1, duration: 650, mediaType: .video)

        let sut = LeftOffItemWidgetCardModel(makeResolved(node: node))

        #expect(sut.durationText == "10:50")
    }

    @Test("a duration of one hour or more shows hours")
    func longVideoShowsHours() {
        let node = NodeEntity(name: "movie.mp4", handle: 1, duration: 3_725, mediaType: .video)

        let sut = LeftOffItemWidgetCardModel(makeResolved(node: node))

        #expect(sut.durationText == "01:02:05")
    }

    @Test("audio has no duration badge")
    func audioHasNoDuration() {
        let node = NodeEntity(name: "song.mp3", handle: 1, duration: 200, mediaType: nil)

        let sut = LeftOffItemWidgetCardModel(makeResolved(node: node))

        #expect(sut.durationText == nil)
    }

    @Test("a video with no duration has no duration badge")
    func videoWithZeroDurationHasNoBadge() {
        let node = NodeEntity(name: "clip.mp4", handle: 1, duration: 0, mediaType: .video)

        let sut = LeftOffItemWidgetCardModel(makeResolved(node: node))

        #expect(sut.durationText == nil)
    }

    @Test("the card carries the sensitive flag, the name, the id and the node")
    func cardCarriesValues() {
        let node = NodeEntity(name: "photo.jpg", handle: 9, hasThumbnail: true)

        let sut = LeftOffItemWidgetCardModel(makeResolved(node: node, isSensitive: true))

        #expect(sut.isSensitive)
        #expect(sut.name == "photo.jpg")
        #expect(sut.id == 9)
        #expect(sut.node == node)
    }

    @Test("a card whose node gains a thumbnail is not equal to the old card")
    func thumbnailChangeBreaksEquality() {
        let old = LeftOffItemWidgetCardModel(makeResolved(node: NodeEntity(name: "clip.mp4", handle: 1, hasThumbnail: false)))
        let new = LeftOffItemWidgetCardModel(makeResolved(node: NodeEntity(name: "clip.mp4", handle: 1, hasThumbnail: true)))

        #expect(old != new)
    }

    @Test("a card whose node gains a duration is not equal to the old card")
    func durationChangeBreaksEquality() {
        let old = LeftOffItemWidgetCardModel(makeResolved(node: NodeEntity(name: "clip.mp4", handle: 1, duration: 0, mediaType: .video)))
        let new = LeftOffItemWidgetCardModel(makeResolved(node: NodeEntity(name: "clip.mp4", handle: 1, duration: 650, mediaType: .video)))

        #expect(old != new)
    }

    @Test("cards with the same values are equal")
    func sameValuesAreEqual() {
        let node = NodeEntity(name: "clip.mp4", handle: 1, hasThumbnail: true, duration: 650, mediaType: .video)

        #expect(LeftOffItemWidgetCardModel(makeResolved(node: node)) == LeftOffItemWidgetCardModel(makeResolved(node: node)))
    }
}
