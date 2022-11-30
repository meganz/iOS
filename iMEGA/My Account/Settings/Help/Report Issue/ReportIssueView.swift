
import SwiftUI
import MEGASwiftUI

struct ReportIssueView: View {
    @StateObject var viewModel: ReportIssueViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .leading) {
                    if !viewModel.isConnected {
                        WarningView(viewModel: WarningViewModel(warningType: .noInternetConnection))
                    }
                    
                    SubheadlineTextView(text: Strings.Localizable.Help.ReportIssue.describe)
                        .padding()
                    
                    Spacer()
                    
                    TextEditorView(text: $viewModel.details,
                                   placeholder: Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder,
                                   isShowingPlaceholder: viewModel.isShowingPlaceholder)
                    
                    if viewModel.areLogsEnabled {
                        TextWithToggleView(text: Strings.Localizable.Help.ReportIssue.sendLogFile, toggle: $viewModel.isSendLogFileToggleOn)
                        Spacer()
                    }
                }
                .background(Color(.secondarySystemBackground))
                .blur(radius: viewModel.isUploadingLog ? 1 : 0)
                .allowsHitTesting(viewModel.isUploadingLog ? false : true)
                if viewModel.shouldShowUploadLogFileView {
                    UploadLogFileView(title: Strings.Localizable.Help.ReportIssue.uploadingLogFile,
                                      progress: viewModel.progress) {
                        viewModel.showCancelUploadReportAlert()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Strings.Localizable.Help.ReportIssue.title)
            .navigationBarItems(
                leading:
                    Button(Strings.Localizable.cancel) {
                        viewModel.showReportIssueActionSheetIfNeeded()
                    }
                    .actionSheet(isPresented: $viewModel.showingReportIssueActionSheet) {
                        ActionSheet(title: Text(""), buttons: [
                            .destructive(Text(Strings.Localizable.Help.ReportIssue.discardReport)) {
                                viewModel.cancelReport()
                            },
                            .cancel()
                        ])
                    }
                ,
                trailing:
                    Button(Strings.Localizable.send) {
                        viewModel.createTicket()
                    }
                    .font(.body.bold())
                    .disabled(viewModel.shouldDisableSendButton)
            )
            .accentColor(Color.primary)
            .alert(isPresented: $viewModel.showingReportIssueAlert) {
                let alertData = viewModel.reportIssueAlertData()
                if let secondaryButtonAlert = alertData.secondaryButtoTitle {
                    return Alert(title: Text(alertData.title),
                                 message: Text(alertData.message),
                                 primaryButton: .cancel(Text(alertData.primaryButtonTitle)),
                                 secondaryButton: .destructive(Text(secondaryButtonAlert), action: {
                        alertData.secondaryButtonAction?()
                    }))
                } else {
                    return Alert(title: Text(alertData.title),
                                 message: Text(alertData.message),
                                 dismissButton: .default(Text(alertData.primaryButtonTitle)))
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
