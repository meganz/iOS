import MEGADesignToken
import MEGADomain
import SwiftUI

public struct SubscriptionCyclePickerView: View {
    private let options: [SubscriptionCycleEntity]
    private let title: (SubscriptionCycleEntity) -> String
    @Binding private var selection: SubscriptionCycleEntity
    private let savingText: String?

    public init(
        options: [SubscriptionCycleEntity] = [.monthly, .yearly],
        selection: Binding<SubscriptionCycleEntity>,
        title: @escaping (SubscriptionCycleEntity) -> String,
        savingText: String? = nil
    ) {
        self.options = options
        self._selection = selection
        self.title = title
        self.savingText = savingText
    }

    public var body: some View {
        HStack(spacing: TokenSpacing._1) {
            ForEach(options, id: \.self) { option in
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
                Text(title(option))
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? TokenColors.Text.primary.swiftUI : TokenColors.Text.secondary.swiftUI)

                if option == .yearly, let savingText {
                    Text(savingText)
                        .font(.caption)
                        .foregroundStyle(TokenColors.Text.error.swiftUI)
                }
            }
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._2)
            .background(isSelected ? TokenColors.Background.page.swiftUI : .clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct SubscriptionCyclePickerPreview: View {
    @State private var selection: SubscriptionCycleEntity = .yearly

    var body: some View {
        SubscriptionCyclePickerView(
            selection: $selection,
            title: { $0 == .monthly ? "Monthly" : "Yearly" },
            savingText: "Save up to 16%"
        )
        .padding()
    }
}

#Preview {
    SubscriptionCyclePickerPreview()
}
