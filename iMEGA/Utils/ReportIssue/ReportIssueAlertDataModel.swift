struct ReportIssueAlertDataModel {
    var title: String = ""
    var message: String = ""
    var primaryButtonTitle: String = ""
    var secondaryButtoTitle: String? = nil
    var secondaryButtonAction: (() -> Void)? = nil
}
