import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CancellationSurveyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CancellationSurveyViewModel
    
    init(
         viewModel: @autoclosure @escaping () -> CancellationSurveyViewModel
     ) {
         _viewModel = StateObject(wrappedValue: viewModel())
     }

    private var navigationBarBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.157, green: 0.157, blue: 0.188) : Color(red: 0.969, green: 0.969, blue: 0.969)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
                .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : navigationBarBackgroundColor)
            
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack {
                        headerView
                            .padding(.bottom, 15)
                        
                        noReasonSelectedErrorView
                            .padding(.bottom, 15)
                        
                        cancellationReasonListView
                        
                        otherReasonTextView

                        allowToBeContactedCheckBox
                            .padding(.vertical, 20)
                        
                        bottomButtonsView
                    }
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 60, trailing: 16))
                }
                .adaptsToKeyboard()
                .onChange(of: viewModel.isOtherFieldFocused) { isFocused in
                    guard isFocused else { return }
                    withAnimation {
                        scrollProxy.scrollTo(viewModel.otherReasonID, anchor: .center)
                    }
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : .clear)
        .onAppear {
            viewModel.trackViewOnAppear()
            viewModel.setupRandomizedReasonList()
        }
    }
    
    // MARK: Views
    private var navigationBar: some View {
        NavigationBarView(
            leading: {
                Button {
                    viewModel.didTapCancelButton()
                } label: {
                    Text(Strings.Localizable.cancel)
                        .font(.body)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                }
            },
            backgroundColor: .clear
        )
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.Header.title)
                .font(.title3)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .multilineTextAlignment(.center)
            
            Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.Header.subtitle)
                .font(.subheadline)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var noReasonSelectedErrorView: some View {
        if viewModel.showNoReasonSelectedError {
            Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.Error.selectAReason)
                .font(.footnote)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .padding(15)
                .frame(maxWidth: .infinity)
                .background(TokenColors.Notifications.notificationError.swiftUI)
        }
    }
    
    private var cancellationReasonListView: some View {
        ForEach(viewModel.cancellationSurveyReasonList, id: \.id) { reason in
            RadioButton(
                id: reason.id,
                text: reason.title,
                isSelected: viewModel.isReasonSelected(reason)
            ) {
                viewModel.selectReason(reason)
            }
        }
    }
    
    @ViewBuilder
    private var otherReasonTextView: some View {
        if let selectedReason = viewModel.selectedReason, selectedReason.isOtherReason {
            BorderedTextEditorView(
                textInput: $viewModel.otherReasonText,
                isFocused: $viewModel.isOtherFieldFocused,
                config: BorderedTextEditorView.ViewConfig(
                    maxCharacterLimit: viewModel.maximumTextRequired,
                    minCharacterLimit: viewModel.minimumTextRequired,
                    isRequired: true,
                    errorWarningIcon: MEGAAssetsImageProvider.image(named: "errorWarning"),
                    lessThanMinimumCharError: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Error.minimumRequiredCharacterCount(viewModel.minimumTextRequired),
                    emptyFieldError: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Error.enterDetails
                )
            )
            .id(viewModel.otherReasonID)
        }
    }
    
    private var allowToBeContactedCheckBox: some View {
        CheckBoxWithTextButton(
            isChecked: $viewModel.allowToBeContacted,
            text: Strings.Localizable.Accounts.CancelSubscriptionSurvey.AllowToContactCheckbox.title
        )
    }
    
    private var bottomButtonsView: some View {
        Group {
            PrimaryActionButtonView(title: Strings.Localizable.Account.Subscription.Cancel.title) {
                viewModel.didTapCancelSubscriptionButton()
            }
            
            Button {
                viewModel.didTapDontCancelButton()
            } label: {
                Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.DontCancel.title)
                    .frame(height: 50)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .font(.title3)
            }
            .padding(.top, 10)
        }
    }
}
