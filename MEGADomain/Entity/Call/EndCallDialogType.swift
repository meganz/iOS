
enum EndCallDialogType {
    case endCallForMyself
    case endCallForAll
    
    var title: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.title
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.endForAllPopupTitle
        }
    }
    
    var message: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.description
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.popupDescription
        }
    }
    
    var cancelTitle: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.stayOnCallButtonTitle
        case .endCallForAll:
            return Strings.Localizable.cancel
        }
    }
    
    var endCallTitle: String {
        switch self {
        case .endCallForMyself:
            return Strings.Localizable.Meetings.EndCallDialog.endCallNowButtonTitle
        case .endCallForAll:
            return Strings.Localizable.Meetings.EndCall.buttonTitle
        }
    }
}
