import Combine
import MEGADesignToken
import SwiftUI

@available(iOS 16.0, *)
struct NodeDescriptionTextView: View {
    @Environment(\.colorScheme) var colorScheme
    @FocusState var isFocused: Bool
    @StateObject var viewModel: NodeDescriptionTextViewModel

    var body: some View {
        TextField(
            "",
            text: $viewModel.descriptionString,
            prompt: isFocused ? nil : placeholderView,
            axis: .vertical
        )
        .lineLimit(5)
        .submitLabel(.done)
        .focused($isFocused)
        .disabled(viewModel.editingDisabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.body)
        .foregroundStyle(
            isDesignTokenEnabled
            ? TokenColors.Text.primary.swiftUI
            : Color(UIColor.label)
        )
        .background(
            isDesignTokenEnabled
            ? TokenColors.Background.page.swiftUI
            : colorScheme == .dark
            ? Color(UIColor.black2C2C2E)
            : Color(UIColor.whiteFFFFFF)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onChange(of: isFocused) {
            viewModel.isFocused = $0
        }
        .onChange(of: viewModel.isFocused) {
            isFocused = $0
        }
        .onChange(of: viewModel.descriptionString) { newValue in
            viewModel.updatedDescriptionString(newValue: newValue)
        }
    }

    private var placeholderView: Text {
        Text(viewModel.placeholder)
            .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : Color(UIColor.secondaryLabel))
    }
}
