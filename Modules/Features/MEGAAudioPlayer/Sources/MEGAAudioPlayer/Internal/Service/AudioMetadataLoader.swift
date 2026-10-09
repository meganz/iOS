import AVFoundation
import Foundation

/// Parsed, UI-agnostic metadata read from an audio file's embedded tags
/// (ID3 frames for MP3, iTunes / MP4 atoms for m4a / aac, Vorbis comments for FLAC).
/// AVFoundation's common-key abstraction maps every tag format onto the same keys
/// (`TPE1`/`©ART`/`ARTIST` → artist, `APIC`/`covr`/`METADATA_BLOCK_PICTURE` → artwork, …),
/// so the same lookup covers every container the player supports.
struct AudioMetadata: Sendable, Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var artworkData: Data?

    var isEmpty: Bool {
        title == nil && artist == nil && album == nil && artworkData == nil
    }
}

// MARK: - Protocol

protocol AudioMetadataLoading: Sendable {
    func loadMetadata(from url: URL) async throws -> AudioMetadata
}

// MARK: - Implementation
struct AudioMetadataLoader: AudioMetadataLoading {
    func loadMetadata(from url: URL) async throws -> AudioMetadata {
        let asset = AVURLAsset(url: url)

        try Task.checkCancellation()
        var items = try await asset.load(.commonMetadata)
        if items.isEmpty {
            // FLAC's Vorbis comments are not a public metadata format, so they never reach
            // `.commonMetadata` even though each item carries the right `commonKey`. Fall back
            // to every item and match on `commonKey`. AVFoundation only returns these items
            // from iOS 26, so FLAC tags stay unread before that.
            items = try await asset.load(.metadata)
        }
        try Task.checkCancellation()

        return AudioMetadata(
            title: try await Self.string(in: items, for: .commonKeyTitle),
            artist: try await Self.string(in: items, for: .commonKeyArtist),
            album: try await Self.string(in: items, for: .commonKeyAlbumName),
            artworkData: try await Self.data(in: items, for: .commonKeyArtwork)
        )
    }

    // MARK: - Private

    private static func string(in items: [AVMetadataItem], for key: AVMetadataKey) async throws -> String? {
        try await items.first { $0.commonKey == key }?.load(.value) as? String
    }

    private static func data(in items: [AVMetadataItem], for key: AVMetadataKey) async throws -> Data? {
        try await items.first { $0.commonKey == key }?.load(.value) as? Data
    }
}
