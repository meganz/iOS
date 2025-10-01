@testable import MEGA
import MEGAAppSDKRepoMock
import Testing

@Suite("Audio Player Playlist Shift Strategies")
struct AudioPlayerPlaylistShiftStrategyTests {
    static let anyNode = MockNode(handle: 1)

    // MARK: - Default Strategy
    @Suite("Default")
    struct DefaultStrategy {

        @Test("returns empty when tracks is empty")
        func emptyReturnsEmpty() {
            let sut = makeDefaultSUT()
            let start = makeItem("name-1")

            let result = sut.shift(tracks: [], startItem: start)

            #expect(result.isEmpty)
        }

        @Test("single track returns the same item")
        func singleTrackReturnsStartItem() {
            let sut = makeDefaultSUT()
            let item = makeItem("name-1")

            let result = sut.shift(tracks: [item], startItem: item)

            #expect(result == [item])
        }

        @Test("reorders so start item goes first and preserves relative order of others")
        func multipleTracksReordered() {
            let sut = makeDefaultSUT()
            let item1 = makeItem("name-1")
            let item2 = makeItem("name-2")
            let item3 = makeItem("name-3")

            let result = sut.shift(tracks: [item1, item2, item3], startItem: item3)

            #expect(result == [item3, item1, item2])
        }
    }

    // MARK: - All Audio As Playlist Strategy
    @Suite("AllAudioAsPlaylist")
    struct AllAudioAsPlaylistStrategy {

        @Test("returns empty when tracks is empty")
        func emptyReturnsEmpty() {
            let sut = makeAllAudioSUT()
            let start = makeItem("name-1")

            let result = sut.shift(tracks: [], startItem: start)

            #expect(result.isEmpty)
        }

        @Test("single track returns the same item")
        func singleTrackReturnsStartItem() {
            let sut = makeAllAudioSUT()
            let item = makeItem("name-1")

            let result = sut.shift(tracks: [item], startItem: item)

            #expect(result == [item])
        }

        @Test("reorders so start item goes first and preserves relative order of others")
        func multipleTracksReordered() {
            let sut = makeAllAudioSUT()
            let item1 = makeItem("name-1", file: "name-1.mp3")
            let item2 = makeItem("name-2", file: "name-2.mp3")
            let item3 = makeItem("name-3", file: "name-3.mp3")

            let result = sut.shift(tracks: [item1, item2, item3], startItem: item3)

            #expect(result.count == 3)
            #expect(result[0].name == item3.name)
            #expect(result[1].name == item1.name)
            #expect(result[2].name == item2.name)
        }
    }
    
    // MARK: - Shared Helpers

    private static func makeDefaultSUT() -> AudioPlayerDefaultPlaylistShiftStrategy {
        AudioPlayerDefaultPlaylistShiftStrategy()
    }

    private static func makeAllAudioSUT() -> AudioPlayerAllAudioAsPlaylistShiftStrategy {
        AudioPlayerAllAudioAsPlaylistShiftStrategy()
    }

    private static func makeItem(_ name: String, file: String? = nil) -> AudioPlayerItem {
        AudioPlayerItem(
            name: name,
            url: anyURL(fileName: file),
            node: anyNode
        )
    }

    private static func anyURL(fileName: String? = nil) -> URL {
        let component = fileName ?? UUID().uuidString
        return URL(string: "https://some-file-link.com/\(component)")!
    }
}
