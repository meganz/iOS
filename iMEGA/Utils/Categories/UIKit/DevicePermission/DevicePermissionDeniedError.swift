import Foundation

/// An error type that user denied the device specified access request.
enum DevicePermissionDeniedError: Error {
    case video                  // Video Permission Access
    case photos                 // Photos Permission Access
    case audio                  // Audio Permission Access
    case audioForIncomingCall   // Incoming audio call Permission Access
}
