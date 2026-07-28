import MEGADesignToken
import MEGADomain
import SwiftUI

struct SubscriptionCyclePickerView: View {
    struct Dependency {
        let plans: [PlanEntity]
    }

    private let viewModel: SubscriptionCycleViewModel
    @Binding private var selection: SubscriptionCycleEntity

    init(dependency: Dependency, selection: Binding<SubscriptionCycleEntity>) {
        self.viewModel = SubscriptionCycleViewModel(plans: dependency.plans)
        self._selection = selection
    }

    var body: some View {
        HStack(spacing: TokenSpacing._1) {
            ForEach(viewModel.options, id: \.self) { option in
                segment(for: option)
            }
        }
        .padding(TokenSpacing._1)
        .background(TokenColors.Button.secondary.swiftUI)
        .clipShape(Capsule())
    }

    private func segment(for option: SubscriptionCycleEntity) -> some View {
        let isSelected = option == selection

        return Button {
            selection = option
        } label: {
            HStack(spacing: TokenSpacing._2) {
                Text(viewModel.title(for: option))
                    .font(isSelected ? .caption.weight(.semibold) : .caption)
                    .foregroundStyle(isSelected ? TokenColors.Text.primary.swiftUI : TokenColors.Text.secondary.swiftUI)

                if option == .yearly, let savingText = viewModel.savingText {
                    Text(savingText)
                        .font(.caption)
                        .foregroundStyle(TokenColors.Text.brand.swiftUI)
                }
            }
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            .background(isSelected ? TokenColors.Background.page.swiftUI : .clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
