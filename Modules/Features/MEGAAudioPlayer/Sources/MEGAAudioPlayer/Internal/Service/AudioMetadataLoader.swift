import AVFoundation
import Foundation

/// Parsed, UI-agnostic metadata read from an audio file's embedded tags
/// (ID3 frames for MP3, iTunes / MP4 atoms for m4a / aac). AVFoundation's
/// common-key abstraction maps both tag formats onto the same keys
/// (`TPE1`/`©ART` → artist, `APIC`/`covr` → artwork, …), so a single read
/// path covers every container the player supports.
struct AudioMetadata: Sendable, Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var artworkData: Data?

    /// Track duration in seconds. `nil` when the asset reports an
    /// indefinite / unavailable duration (e.g. a live stream). With
    /// `AVURLAssetPreferPreciseDurationAndTimingKey` off this can be an estimate
    /// for headerless VBR MP3; the engine's live duration supersedes it later.
    var duration: TimeInterval?

    var isEmpty: Bool {
        title == nil && artist == nil && album == nil && artworkData == nil && duration == nil
    }
}

// MARK: - Protocol

protocol AudioMetadataLoading: Sendable {
    func loadMetadata(from url: URL) async throws -> AudioMetadata
}

// MARK: - Implementation
struct AudioMetadataLoader: AudioMetadataLoading {
    func loadMetadata(from url: URL) async throws -> AudioMetadata {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        )

        try Task.checkCancellation()
        let items = try await asset.load(.commonMetadata)
        try Task.checkCancellation()
        let duration = Self.seconds(from: try await asset.load(.duration))
        try Task.checkCancellation()

        return AudioMetadata(
            title: try await Self.string(in: items, for: .commonKeyTitle),
            artist: try await Self.string(in: items, for: .commonKeyArtist),
            album: try await Self.string(in: items, for: .commonKeyAlbumName),
            artworkData: try await Self.data(in: items, for: .commonKeyArtwork),
            duration: duration
        )
    }

    // MARK: - Private

    private static func string(in items: [AVMetadataItem], for key: AVMetadataKey) async throws -> String? {
        try await items.first { $0.commonKey == key }?.load(.value) as? String
    }

    private static func data(in items: [AVMetadataItem], for key: AVMetadataKey) async throws -> Data? {
        try await items.first { $0.commonKey == key }?.load(.value) as? Data
    }

    /// Convert a track `CMTime` duration to seconds, rejecting invalid,
    /// indefinite, or non-positive values (matches the engine's duration guard).
    private static func seconds(from time: CMTime) -> TimeInterval? {
        guard time.isNumeric else { return nil }
        let seconds = CMTimeGetSeconds(time)
        return (seconds.isFinite && seconds > 0) ? seconds : nil
    }
}
