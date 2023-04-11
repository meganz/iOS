struct ReportIssueAlertDataModel {
    var title: String = ""
    var message: String = ""
    var primaryButtonTitle: String = ""
    var primaryButtonAction: (() -> Void)? = nil
    var secondaryButtoTitle: String? = nil
    var secondaryButtonAction: (() -> Void)? = nil
}
