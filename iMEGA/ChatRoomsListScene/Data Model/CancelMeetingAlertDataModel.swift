struct CancelMeetingAlertDataModel {
    var title: String = ""
    var message: String = ""
    var primaryButtonTitle: String = ""
    var primaryButtonAction: (() -> Void)?
    var secondaryButtonTitle: String
}
