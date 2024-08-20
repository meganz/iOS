import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CancelSubscriptionStepsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: CancelSubscriptionStepsViewModel
    
    private var bodyBackgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var navigationBarBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.157, green: 0.157, blue: 0.188) : Color(red: 0.969, green: 0.969, blue: 0.969)
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .frame(height: 60)
                .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : navigationBarBackgroundColor)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.title)
                        .font(.title3)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                    
                    Text(viewModel.message)
                        .font(.body)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
                    
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
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : bodyBackgroundColor)
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
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
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
