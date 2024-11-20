import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CancellationSurveyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CancellationSurveyViewModel
    
    init(viewModel: @autoclosure @escaping () -> CancellationSurveyViewModel) {
         _viewModel = StateObject(wrappedValue: viewModel())
     }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
                .background(TokenColors.Background.surface1.swiftUI)
            
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack {
                        headerView
                            .padding(.bottom, 15)
                        
                        if viewModel.surveyFormError == .noSelectedReason {
                            noReasonSelectedErrorView
                                .padding(.bottom, 15)
                        }
                        
                        cancellationReasonListView
                        
                        otherReasonTextView
                        
                        allowToBeContactedCheckBoxView
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
        .background(TokenColors.Background.surface1.swiftUI)
        .onAppear {
            viewModel.trackViewOnAppear()
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
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                }
            },
            backgroundColor: .clear
        )
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.Header.title)
                .font(.title3)
                .bold()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .multilineTextAlignment(.center)
            
            Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.Header.subtitle)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .multilineTextAlignment(.center)
            
            if viewModel.isMultipleSelectionEnabled {
                Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.SubHeader.title)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var noReasonSelectedErrorView: some View {
        Text(Strings.Localizable.Accounts.CancelSubscriptionSurvey.Error.selectAReason)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(TokenColors.Notifications.notificationError.swiftUI)
    }
    
    @ViewBuilder
    private var cancellationReasonListView: some View {
        if viewModel.isMultipleSelectionEnabled {
            ForEach(viewModel.cancellationSurveyReasonList, id: \.id) { reason in
                CheckBoxWithTextButton(
                    isChecked: viewModel.isReasonSelected(reason),
                    id: reason.id.rawValue,
                    text: reason.title,
                    font: Font.subheadline
                ) { _ in
                    viewModel.updateSelectedReason(reason)
                }
            }
        } else {
            ForEach(viewModel.cancellationSurveyReasonList, id: \.id) { reason in
                RadioButton(
                    id: String(reason.id.rawValue),
                    text: reason.title,
                    isSelected: viewModel.isReasonSelected(reason)
                ) {
                    viewModel.updateSelectedReason(reason)
                }
                
                if viewModel.surveyFormError == .noSelectedFollowUpReason(reason) {
                    noReasonSelectedErrorView
                }
                
                if let followUpReasons = viewModel.followUpReasons(reason), viewModel.isReasonSelected(reason) {
                    VStack {
                        ForEach(followUpReasons, id: \.id) { followUpReason in
                            RadioButton(
                                id: followUpReason.id.rawValue,
                                text: followUpReason.title,
                                isSelected: viewModel.isFollowUpReasonSelected(followUpReason)
                            ) {
                                viewModel.updateSelectedFollowUpReason(followUpReason)
                            }
                        }
                    }.padding(.leading, 30)
                }
            }
        }
    }
    
    @ViewBuilder
    private var otherReasonTextView: some View {
        if viewModel.showOtherField {
            BorderedTextEditorView(
                textInput: $viewModel.otherReasonText,
                isFocused: $viewModel.isOtherFieldFocused,
                showMinLimitOrEmptyError: $viewModel.showMinLimitOrEmptyOtherFieldError,
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
            .onChange(of: viewModel.dismissKeyboard) { dismiss in
                guard dismiss else { return }
                hideKeyboard()
                viewModel.dismissKeyboard = false
            }
        }
    }
    
    private var allowToBeContactedCheckBoxView: some View {
        VStack(spacing: 20) {
            Divider()
                .background(TokenColors.Border.strong.swiftUI)
                .opacity(viewModel.isMultipleSelectionEnabled ? 1 : 0)
                
            CheckBoxWithTextButton(
                isChecked: viewModel.allowToBeContacted,
                text: Strings.Localizable.Accounts.CancelSubscriptionSurvey.AllowToContactCheckbox.title
            ) { isChecked in
                viewModel.setAllowToBeContacted(isChecked)
            }
        }
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
