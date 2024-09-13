import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ReportIssueView: View {
    @StateObject var viewModel: ReportIssueViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                
                if !viewModel.isConnected {
                    WarningBannerView(viewModel: WarningBannerViewModel(warningType: .noInternetConnection))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                SubheadlineTextView(text: Strings.Localizable.Help.ReportIssue.describe)
                    .padding()
                
                Spacer()
                
                TextEditorView(
                    text: $viewModel.details
                        .onChange({ _ in
                            viewModel.isNotReachingMinimumCharacter = false
                        }),
                    placeholder: Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder
                )
                
                VStack(spacing: 0) {
                    ErrorView(
                        error: Strings.Localizable.Help.ReportIssue.MinCharacterNotReach.error
                    )
                    .frame(height: 38)
                    .opacity(viewModel.isNotReachingMinimumCharacter ? 1 : 0)
                        
                    if viewModel.areLogsEnabled {
                        TextWithToggleView(text: Strings.Localizable.Help.ReportIssue.sendLogFile, toggle: $viewModel.isSendLogFileToggleOn
                        )
                        .padding(.bottom, 38)
                    }
                }.background(TokenColors.Background.page.swiftUI)
            }
            
            .background(TokenColors.Background.surface1.swiftUI)
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
        }, backgroundColor: TokenColors.Background.surface1.swiftUI)
    }
    
    private var leftNavigationButton: some View {
        Button(Strings.Localizable.cancel) {
            viewModel.showReportIssueActionSheetIfNeeded()
        }
        .accentColor(TokenColors.Text.primary.swiftUI)
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
            guard viewModel.details.count > 10 else {
                viewModel.isNotReachingMinimumCharacter = true
                return
            }
            Task {
                await viewModel.createTicket()
            }
        }
        .accentColor(TokenColors.Text.primary.swiftUI)
        .font(.body.bold())
        .disabled(viewModel.shouldDisableSendButton)
    }
}
