/// Represents a simplified, visual backup status for backup folders. This enum aggregates multiple detailed backup statuses into one user-facing display status.
/// The purpose is to simplify the status shown in the UI.
///
/// Available statuses (UI Display):
/// - `Inactive:` No backup activity detected for over 60 days.
/// - `Error:` An error has occurred in the backup process.
/// - `Disabled:` Backup appears as disabled or paused. Only available for CU backups.
/// - `Paused:` Backup is currently paused. Not available for CU.
/// - `Updating:` Backup is currently in progress (e.g., syncing, scanning, or initializing).
/// - `Up to date:` Backup is current and all data is synchronized.
public enum BackupDisplayStatusEntity: Sendable {
    case inactive
    case error
    case disabled
    case paused
    case updating
    case upToDate
    case noCameraUploads
}
