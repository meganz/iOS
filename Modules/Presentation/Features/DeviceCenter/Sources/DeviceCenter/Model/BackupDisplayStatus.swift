/// Represents a simplified, visual device backup status for devices in the Device Center. This enum aggregates multiple detailed device statuses into one user-facing display status.
/// The purpose is to simplify the status shown in the UI.
///
/// Available statuses (UI Display):
/// - `Inactive:` The device is not active or has been offline for an extended period (60 days or more).
/// - `Attention needed:` An error or pause has occurred in one or more of the device's backups.
/// - `Updating:` The device is currently updating (e.g., syncing (SYNC), backing up (BACKUP), or uploading (CU)).
/// - `Up to date:` All backups inside the device are up to date.
public enum DeviceDisplayStatusEntity: Sendable {
    case inactive
    case attentionNeeded
    case updating
    case upToDate
}
