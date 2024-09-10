import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CancelSubscriptionStepsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: CancelSubscriptionStepsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
                .background(TokenColors.Background.surface1.swiftUI)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.title)
                        .font(.title3)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    
                    Text(viewModel.message)
                        .font(.body)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    
                    ForEach(viewModel.sections, id: \.title) { section in
                        StepSectionView(
                            sectionTitle: section.title,
                            steps: section.steps
                        )
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                
            }
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        .background(TokenColors.Background.page.swiftUI)
        .task {
            viewModel.setupStepList()
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
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
            center: {
                NavigationTitleView(title: Strings.Localizable.Account.Subscription.Cancel.title)
            },
            leadingWidth: 70,
            trailingWidth: 70,
            backgroundColor: .clear
        )
    }
}
