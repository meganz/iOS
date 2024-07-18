import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ReportIssueView: View {
    @StateObject var viewModel: ReportIssueViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                navigationBar
                
                if !viewModel.isConnected {
                    WarningView(viewModel: WarningViewModel(warningType: .noInternetConnection))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                SubheadlineTextView(text: Strings.Localizable.Help.ReportIssue.describe)
                    .padding()
                
                Spacer()
                
                TextEditorView(text: $viewModel.details,
                               placeholder: Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder)
                
                if viewModel.areLogsEnabled {
                    TextWithToggleView(text: Strings.Localizable.Help.ReportIssue.sendLogFile, toggle: $viewModel.isSendLogFileToggleOn)
                    Spacer()
                }
            }
            .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color(.secondarySystemBackground))
            .blur(radius: viewModel.isUploadingLog ? 1 : 0)
            .allowsHitTesting(viewModel.isUploadingLog ? false : true)
            .task {
                await viewModel.monitorNetworkChanges()
            }
            
            if viewModel.shouldShowUploadLogFileView {
                UploadLogFileView(title: Strings.Localizable.Help.ReportIssue.uploadingLogFile,
                                  progress: viewModel.progress) {
                    viewModel.showCancelUploadReportAlert()
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .alert(isPresented: $viewModel.showingReportIssueAlert) {
            let alertData = viewModel.reportIssueAlertData()
            if let secondaryButtonAlert = alertData.secondaryButtonTitle {
                return Alert(title: Text(alertData.title),
                             message: Text(alertData.message),
                             primaryButton: .cancel(Text(alertData.primaryButtonTitle), action: {
                    Task {
                        await alertData.primaryButtonAction?()
                    }
                })
                             , secondaryButton: .destructive(Text(secondaryButtonAlert), action: {
                    Task {
                        await alertData.secondaryButtonAction?()
                    }
                }))
            } else {
                return Alert(title: Text(alertData.title),
                             message: Text(alertData.message),
                             dismissButton: .default(Text(alertData.primaryButtonTitle), action: {
                    Task {
                        await alertData.primaryButtonAction?()
                    }
                }))
            }
        }
    }
    
    private var navigationBar: some View {
        NavigationBarView(leading: {
            leftNavigationButton
        }, trailing: {
            rightNavigationBarButton
        }, center: {
            NavigationTitleView(title: Strings.Localizable.Help.ReportIssue.title)
        }, backgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : UIColor.navigationBg.swiftUI)
    }
    
    private var leftNavigationButton: some View {
        Button(Strings.Localizable.cancel) {
            viewModel.showReportIssueActionSheetIfNeeded()
        }
        .accentColor(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary)
        .actionSheet(isPresented: $viewModel.showingReportIssueActionSheet) {
            ActionSheet(title: Text(""), buttons: [
                .destructive(Text(Strings.Localizable.Help.ReportIssue.discardReport)) {
                    viewModel.dismissReport()
                },
                .cancel()
            ])
        }
    }
    
    private var rightNavigationBarButton: some View {
        Button(Strings.Localizable.send) {
            Task {
                await viewModel.createTicket()
            }
        }
        .accentColor(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary)
        .font(.body.bold())
        .disabled(viewModel.shouldDisableSendButton)
    }
}
