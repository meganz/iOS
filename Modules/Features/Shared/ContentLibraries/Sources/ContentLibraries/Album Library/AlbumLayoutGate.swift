import Foundation

/// Single source of truth for the Album content layout style.
///
/// Why: the album content view was migrated to the masonry grid + sort header
/// as part of `iosMediaRevamp`, but user feedback was negative and the layout
/// is being rolled back. The masonry / sort-header code is intentionally kept;
///
/// How to apply: replaces the `isMediaRevampEnabled` portion of the album
/// layout decision in `PhotoLibraryModeAllCollectionViewModel`,
/// `PhotoLibraryCollectionLayoutBuilder`, and `AlbumContentViewModel`. Other
/// `iosMediaRevamp`-driven behaviour (cell styling, empty view, FAB, etc.)
/// is unaffected and still follows the remote flag.
///
/// When the team decides what flag should drive this (local debug toggle,
/// remote feature flag, user setting), only this property body needs to change.
public enum AlbumLayoutGate {
    /// Whether the album content view should use the masonry grid plus the
    /// sort-style section header. `false` restores the legacy multi-column
    /// grid and per-date section header.
    public static var isMasonryLayoutEnabled: Bool { false }
}
