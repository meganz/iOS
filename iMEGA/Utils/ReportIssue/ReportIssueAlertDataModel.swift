struct ReportIssueAlertDataModel {
    var title: String = ""
    var message: String = ""
    var primaryButtonTitle: String = ""
    var primaryButtonAction: (() async -> Void)?
    var secondaryButtonTitle: String?
    var secondaryButtonAction: (() async -> Void)?
}
