struct ReportIssueAlertDataModel {
    var title: String = ""
    var message: String = ""
    var primaryButtonTitle: String = ""
    var primaryButtonAction: (() -> Void)?
    var secondaryButtoTitle: String?
    var secondaryButtonAction: (() -> Void)?
}
