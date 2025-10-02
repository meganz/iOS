@testable @preconcurrency import MEGA
import Testing

@MainActor
struct AudioPlayerMoveDirectionTests {
    private static func makeSUT() -> AudioPlayer {
        let urls = (1...4).map { URL(string: "file://\($0).mp3")! }
        let items = urls.map { AudioPlayerItem(url: $0) }
        let sut = AudioPlayer(player: AVQueuePlayer(items: items))
        sut.tracks = items
        return sut
    }
    
    private static func assertMove(
        from fromIndex: Int,
        to toIndex: Int,
        direction: MovementDirection
    ) {
        let sut = makeSUT()
        let item = sut.tracks[fromIndex]
        sut.move(of: item, to: IndexPath(row: toIndex, section: 0), direction: direction)
        #expect(sut.tracks[toIndex] === item)
    }
    
    private static func assertNoOp(
        direction: MovementDirection,
        at index: Int
    ) {
        let sut = makeSUT()
        let original = sut.tracks
        let item = original[index]
        sut.move(of: item, to: IndexPath(row: index, section: 0), direction: direction)
        #expect(sut.tracks.elementsEqual(original, by: { $0 === $1 }))
    }
    
    @Suite("move(of:to:direction:) – Direction .up")
    @MainActor struct MoveUpTests {
        @Test("Moving an item one position up shifts it earlier in `tracks`")
        func movesOnePositionUp() {
            assertMove(
                from: 2,
                to: 1,
                direction: .up
            )
        }
        
        @Test("Moving the first item up does nothing")
        func movingFirstItemUpNoOp() {
            assertNoOp(
                direction: .up,
                at: 0
            )
        }
    }
    
    @Suite("move(of:to:direction:) – Direction .down")
    @MainActor struct MoveDownTests {
        @Test("Moving an item one position down shifts it later in `tracks`")
        func movesOnePositionDown() {
            assertMove(
                from: 1,
                to: 2,
                direction: .down
            )
        }
        
        @Test("Moving the last item down does nothing")
        func movingLastItemDownNoOp() throws {
            let sut = makeSUT()
            let lastIndex = sut.tracks.count - 1
            let item = sut.tracks[lastIndex]
            let original = sut.tracks
            
            sut.move(of: item, to: IndexPath(row: lastIndex, section: 0), direction: .down)
            
            #expect(sut.tracks.elementsEqual(original, by: { $0 === $1 }))
        }
    }
}
