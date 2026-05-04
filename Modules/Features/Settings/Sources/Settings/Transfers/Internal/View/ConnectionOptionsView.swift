import MEGAAssets
import MEGADesignToken
import SwiftUI

struct ConnectionOptionsView: View {
    let title: String
    let options: [Int]
    let selection: Int
    let suffix: (Int) -> String?
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    private let height: CGFloat = 58

    var body: some View {
        VStack(spacing: 0) {
            titleView
            ScrollView {
                LazyVStack(spacing: 0) {
                    optionsListView
                }
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.medium, .large])
    }

    private var titleView: some View {
        Text(title)
            .font(.body)
            .bold()
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, TokenSpacing._6)
            .padding(.horizontal, TokenSpacing._5)
    }

    private var optionsListView: some View {
        ForEach(options, id: \.self) { option in
            VStack(spacing: 0) {
                Divider()
                    .overlay(TokenColors.Border.subtle.swiftUI)

                Button {
                    onSelect(option)
                    dismiss()
                } label: {
                    HStack {
                        label(for: option)
                        Spacer()
                        if option == selection {
                            MEGAAssets.Image.check
                                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        }
                    }
                    .padding(.horizontal, TokenSpacing._5)
                }
                .frame(height: height)
            }
        }
    }

    private func label(for option: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(option)")
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            if let suffix = suffix(option) {
                Text(" (\(suffix))")
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
    }
}
