import MEGADesignToken
import SwiftUI

struct SubscriptionPurchaseChipOption: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let onSelect: () -> Void

    static func == (lhs: SubscriptionPurchaseChipOption, rhs: SubscriptionPurchaseChipOption) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

struct SubscriptionPurchaseChipsSelectorView: View {
    let options: [SubscriptionPurchaseChipOption]
    @Binding var selected: SubscriptionPurchaseChipOption?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(options) { option in
                SubscriptionPurchaseChipView(
                    option: option,
                    isSelected: option == selected,
                    onSelect: {
                        selected = option
                        option.onSelect()
                    }
                )
            }
        }
    }
}

private struct SubscriptionPurchaseChipView: View {
    let option: SubscriptionPurchaseChipOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(option.title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? TokenColors.Brand.onContainer.swiftUI : TokenColors.Text.primary.swiftUI)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .background(
                    isSelected ? TokenColors.Brand.containerDefault.swiftUI : TokenColors.Button.secondary.swiftUI
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
