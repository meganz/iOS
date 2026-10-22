@testable import MEGA
import MEGAAppSDKRepoMock
import MEGAAudioPlayer
import Testing

@MainActor
@Suite("Revamped audio playback source")
struct RevampedAudioPlaybackSourceTests {

    /// A folder can carry an audio extension in its name, with or without a dot (IOS-12866).
    @Test("The queue keeps only the audio files, never a folder named like one")
    func queueExcludesFoldersWithAudioExtension() throws {
        let song = MockNode(handle: 1, name: "song.mp3")
        let siblings: [MEGANode] = [
            song,
            MockNode(handle: 2, name: "MP3", nodeType: .folder),
            MockNode(handle: 3, name: "Audios.mp3", nodeType: .folder),
            MockNode(handle: 4, name: "Audios.wav", nodeType: .folder),
            MockNode(handle: 5, name: "voice.wav"),
            MockNode(handle: 6, name: "notes.txt")
        ]

        let source = song.makeRevampedPlaybackSource(
            node: song,
            fileLink: nil,
            isFolderLink: false,
            chatId: nil,
            messageId: nil,
            allNodes: siblings,
            sourcePage: .unknown
        )

        guard case let .cloudNode(node, queue) = try #require(source) else {
            Issue.record("Expected a cloud node source, got \(String(describing: source))")
            return
        }
        #expect(node.handle == 1)
        #expect(queue.map(\.handle) == [1, 5])
    }
}
