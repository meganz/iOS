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

extension PitagTargetEntity {
    public func toMEGAPitagTrigger() -> MEGAPitagTarget {
        switch self {
        case .notApplicable: .notApplicable
        case .cloudDrive: .cloudDrive
        case .chat1To1: .chat1To1
        case .chatGroup: .chatGroup
        case .noteToSelf: .noteToSelf
        case .incomingShare: .incomingShare
        case .multipleChats: .multipleChats
        }
    }
}

extension UploadOptionsEntity {
    public func toMEGAUploadOptions() -> MEGAUploadOptions {
        MEGAUploadOptions(
            fileName: fileName,
            mtime: mtime,
            appData: appData,
            isSourceTemporary: isSourceTemporary,
            startFirst: startFirst,
            pitagTrigger: pitagTrigger.toMEGAPitagTrigger(),
            isChatUpload: isChatUpload,
            pitagTarget: pitagTarget.toMEGAPitagTrigger()
        )
    }
}
