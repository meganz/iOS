import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ReportIssueView: View {
    @StateObject private var viewModel: ReportIssueViewModel
    private let noConnectionBannerViewModel = WarningBannerViewModel(warningType: .noInternetConnection)

    init(viewModel: @autoclosure @escaping () -> ReportIssueViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar

                if !viewModel.isConnected {
                    WarningBannerView(viewModel: noConnectionBannerViewModel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SubheadlineTextView(text: Strings.Localizable.Help.ReportIssue.describe)
                    .padding()

                Spacer()

                TextEditorView(
                    text: $viewModel.details,
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
        .alert(viewModel.reportIssueAlertData().title, isPresented: $viewModel.showingReportIssueAlert) {
            let alertData = viewModel.reportIssueAlertData()
            Button(alertData.primaryButtonTitle) {
                Task {
                    await alertData.primaryButtonAction?()
                }
            }
            if let secondaryButtonTitle = alertData.secondaryButtonTitle {
                Button(secondaryButtonTitle, role: .destructive) {
                    Task {
                        await alertData.secondaryButtonAction?()
                    }
                }
            }
        } message: {
            Text(viewModel.reportIssueAlertData().message)
        }
    }

    private var navigationBar: some View {
        NavigationBarView(leading: {
            if #available(iOS 26.0, *) {
                leftNavigationButton
                    .buttonStyle(.glass)
            } else {
                leftNavigationButton
            }
        }, trailing: {
            if #available(iOS 26.0, *) {
                rightNavigationBarButton
                    .buttonStyle(.glass)
            } else {
                rightNavigationBarButton
            }
        }, center: {
            NavigationTitleView(title: Strings.Localizable.Help.ReportIssue.title)
        }, backgroundColor: TokenColors.Background.surface1.swiftUI)
    }

    private var leftNavigationButton: some View {
        Button(Strings.Localizable.cancel) {
            viewModel.showReportIssueActionSheetIfNeeded()
        }
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
        .confirmationDialog("", isPresented: $viewModel.showingReportIssueActionSheet) {
            Button(Strings.Localizable.Help.ReportIssue.discardReport, role: .destructive) {
                viewModel.dismissReport()
            }
        }
    }

    private var rightNavigationBarButton: some View {
        Button(Strings.Localizable.send) {
            Task {
                await viewModel.sendReport()
            }
        }
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
        .font(.body.bold())
        .disabled(viewModel.shouldDisableSendButton)
    }
}
