import Foundation
@testable import MEGAAudioPlayer
import Testing

@Suite("AudioMetadataLoader")
struct AudioMetadataLoaderTests {
    static func fixtureURL(_ name: String) throws -> URL {
        try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
    }

    // AVFoundation only returns Vorbis comment items from iOS 26; earlier versions return none.
    @available(iOS 26, *)
    @Test("Reads Vorbis comment tags and embedded artwork from FLAC")
    func flacMetadata() async throws {
        let metadata = try await AudioMetadataLoader().loadMetadata(from: Self.fixtureURL("tagged.flac"))

        #expect(metadata.title == "Flac Title")
        #expect(metadata.artist == "Flac Artist")
        #expect(metadata.album == "Flac Album")
        #expect(metadata.artworkData != nil)
    }

    @Test("Reads ID3 tags and embedded artwork from MP3")
    func mp3Metadata() async throws {
        let metadata = try await AudioMetadataLoader().loadMetadata(from: Self.fixtureURL("tagged.mp3"))

        #expect(metadata.title == "Mp3 Title")
        #expect(metadata.artist == "Mp3 Artist")
        #expect(metadata.album == "Mp3 Album")
        #expect(metadata.artworkData != nil)
    }
}
