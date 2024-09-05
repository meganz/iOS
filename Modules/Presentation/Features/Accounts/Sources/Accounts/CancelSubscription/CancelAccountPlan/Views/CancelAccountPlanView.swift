import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CancelAccountPlanView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: CancelAccountPlanViewModel
    
    private var bodyBackgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var navigationBarBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.157, green: 0.157, blue: 0.188) : Color(red: 0.969, green: 0.969, blue: 0.969)
    }
    
    private var featureListHeaderBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.286, green: 0.290, blue: 0.302) : Color(red: 0.847, green: 0.851, blue: 0.859)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
                .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : navigationBarBackgroundColor)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    headerView()
                    cancelAccountPlanBodyView()
                    footerView()
                }
                .padding(.bottom, 20.0)
            }
            .padding(.horizontal, 16.0)
            Spacer()
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : .clear)
        .task {
            await viewModel.setupFeatureList()
        }
        .sheet(isPresented: $viewModel.showCancellationSurvey) {
            CancellationSurveyView(
                viewModel: viewModel.makeCancellationSurveyViewModel()
            )
        }
        .sheet(isPresented: $viewModel.showCancellationSteps) {
            CancelSubscriptionStepsView(
                viewModel: CancelSubscriptionStepsViewModel(
                    helper: CancelSubscriptionStepsHelper(type: viewModel.cancellationStepsSubscriptionType)
                )
            )
        }
    }
    
    @ViewBuilder
    private var navigationBar: some View {
        NavigationBarView(
            leading: {
                Button {
                    viewModel.dismiss()
                } label: {
                    Text(Strings.Localizable.cancel)
                        .font(.body)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                }
            },
            backgroundColor: .clear
        )
    }
    
    @ViewBuilder
    private func featureListHeaderView() -> some View {
        HStack {
            Text(Strings.Localizable.Feature.title)
                .font(.footnote)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(Strings.Localizable.free)
                .font(.footnote)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .frame(maxWidth: .infinity)
           
            Text(viewModel.currentPlanName)
                .font(.footnote)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8.0)
        .frame(height: 40)
        .background(isDesignTokenEnabled ? TokenColors.Background.surface2.swiftUI : featureListHeaderBackgroundColor)
    }
    
    @ViewBuilder
    private func cancelAccountPlanBodyView() -> some View {
        VStack(spacing: 10) {
            featureListHeaderView()
            
            ForEach(viewModel.features) { featureDetail in
                FeatureRow(feature: featureDetail)
                Divider()
            }
        }
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : bodyBackgroundColor)
        .cornerRadius(8.0)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        VStack(spacing: 10) {
            Text(Strings.Localizable.Cancellation.Subscription.Header.title)
                .font(.title3)
                .bold()
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .textCase(nil)
                .padding(.top, 10)
            
            Text(Strings.Localizable.Cancellation.Subscription.Header.message(viewModel.currentPlanStorageUsed))
                .font(.subheadline)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
                .textCase(nil)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
                .padding(.bottom, 15)
        }
    }
    
    @ViewBuilder
    private func footerView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            PrimaryActionButtonView(title: Strings.Localizable.Cancellation.Subscription.Keep.Pro.Plan.Button.title(viewModel.currentPlanName)) {
                viewModel.dismiss()
            }
            
            SecondaryActionButtonView(title: Strings.Localizable.Cancellation.Subscription.Continue.Cancellation.Button.title) {
                viewModel.didTapContinueCancellation()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 30)
        .padding(.horizontal, 5)
    }
}
