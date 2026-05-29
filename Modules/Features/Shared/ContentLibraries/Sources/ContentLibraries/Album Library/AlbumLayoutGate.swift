import Foundation
import MEGADomain

/// Single source of truth for the Album content layout style.
///
/// The album content view was migrated to the masonry grid + sort header, but
/// user feedback was negative and the layout is being rolled back behind its
/// own remote feature flag (`iosAlbumMasonryLayout`). The masonry / sort-header
/// code is intentionally kept so re-enabling is just a platform-side flag flip.
public enum AlbumLayoutGate {
    /// Whether the album content view should use the masonry grid plus the
    /// sort-style section header. `false` restores the legacy multi-column
    /// grid and per-date section header. Driven by the `iosAlbumMasonryLayout`
    /// remote feature flag — defaults to `false` (rolled back) until the
    /// flag is explicitly enabled on the platform.
    public static var isMasonryLayoutEnabled: Bool {
        // Read the configuration defensively: tests (and any code path that
        // touches album layout before the host app has called
        // `ContentLibraries.configuration = ...`) would otherwise trip the
        // `fatalError` in `ContentLibraries.configuration` and crash the
        // whole xctest process. Treat "not configured" as rolled back.
        guard let configuration = ContentLibraries._configuration.wrappedValue else { return false }
        return configuration.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosAlbumMasonryLayout)
    }
}
