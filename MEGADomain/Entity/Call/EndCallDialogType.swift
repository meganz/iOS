
enum EndCallDialogType {
    case endCallForMyself
    case endCallForAll
    
    var title: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.title
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.EndForAllAlert.title
        }
    }
    
    var message: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.description
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.EndForAllAlert.description
        }
    }
    
    var cancelTitle: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.stayOnCallButtonTitle
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.EndForAllAlert.cancel
        }
    }
    
    var endCallTitle: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.endCallNowButtonTitle
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.EndForAllAlert.confirm
        }
    }
}
