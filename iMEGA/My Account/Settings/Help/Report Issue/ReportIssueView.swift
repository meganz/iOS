
import SwiftUI
import MEGASwiftUI

@available(iOS 14.0, *)
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
                        viewModel.cancelUploadReport()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Strings.Localizable.Help.ReportIssue.title)
            .navigationBarItems(
                leading:
                    Button(Strings.Localizable.cancel) {
                        viewModel.cancelReport()
                    },
                trailing:
                    Button(Strings.Localizable.send) {
                        viewModel.createTicket()
                    }
                    .font(.body.bold())
                    .disabled(viewModel.shouldDisableSendButton)
            )
            .accentColor(Color.primary)
        }
    }
}
