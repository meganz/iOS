/// Upload trigger tags representing the source of an upload action.
public enum PitagTriggerEntity: Sendable {
    /// Not applicable or default trigger
    case notApplicable
    /// Upload initiated from a file picker
    case picker
    /// Upload initiated from drag and drop
    case dragAndDrop
    /// Upload initiated from camera
    case camera
    /// Upload initiated from a scanner
    case scanner
    /// Upload initiated by sync algorithm
    case syncAlgorithm
    /// Upload initiated from share from app
    case shareFromApp
    /// Upload initiated from camera capture
    case cameraCapture
    /// Upload initiated from explorer extension
    case explorerExtension
    /// Upload initiated from voice recorder
    case voiceRecorder
}
