import MEGADomain
import MEGASdk

extension PitagTriggerEntity {
    public func toMEGAPitagTrigger() -> MEGAPitagTrigger {
        switch self {
        case .notApplicable: .notApplicable
        case .picker: .picker
        case .dragAndDrop: .dragAndDrop
        case .camera: .camera
        case .scanner: .scanner
        case .syncAlgorithm: .syncAlgorithm
        case .shareFromApp: .shareFromApp
        case .cameraCapture: .cameraCapture
        case .explorerExtension: .explorerExtension
        case .voiceRecorder: .voiceRecorder
        }
    }
}