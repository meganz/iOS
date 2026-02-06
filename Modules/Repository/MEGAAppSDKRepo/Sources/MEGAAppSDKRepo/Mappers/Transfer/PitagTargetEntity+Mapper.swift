import MEGADomain
import MEGASdk

extension PitagTargetEntity {
    public func toMEGAPitagTarget() -> MEGAPitagTarget {
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
