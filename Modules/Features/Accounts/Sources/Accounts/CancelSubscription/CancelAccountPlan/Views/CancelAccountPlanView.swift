import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CancelAccountPlanView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: CancelAccountPlanViewModel
        
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
                .background(TokenColors.Background.surface1.swiftUI)
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
        .background(TokenColors.Background.surface1.swiftUI)
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
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
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
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(Strings.Localizable.free)
                .font(.footnote)
                .bold()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .textCase(nil)
                .frame(maxWidth: .infinity)
           
            Text(viewModel.currentPlanName)
                .font(.footnote)
                .bold()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .textCase(nil)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8.0)
        .frame(height: 40)
        .background(TokenColors.Background.surface2.swiftUI)
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
        .background(TokenColors.Background.page.swiftUI)
        .cornerRadius(8.0)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        VStack(spacing: 10) {
            Text(Strings.Localizable.Cancellation.Subscription.Header.title)
                .font(.title3)
                .bold()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .textCase(nil)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            
            Text(Strings.Localizable.Cancellation.Subscription.Header.message(viewModel.currentPlanStorageUsed))
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
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
