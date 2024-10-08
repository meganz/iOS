import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct KeyRotationView: View {
    @Environment(\.layoutDirection) var layoutDirection

    let title: String
    let rightDetail: String
    let footer: String
    @Binding var isPublicChat: Bool
    let action: (() -> Void)

    private let discolureIndicator = "chevron.right"

    private enum Constants {
        static let disclosureOpacity: CGFloat = 0.6
        static let textOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                HStack {
                    Text(title)
                        .font(.body)
                    Spacer()
                    if isPublicChat {
                        Image(systemName: discolureIndicator)
                            .foregroundColor(UIColor.gray8E8E93.swiftUI.opacity(Constants.disclosureOpacity))
                            .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
                    } else {                        Text(rightDetail)
                            .font(.footnote)
                            .foregroundColor(TokenColors.Icon.secondary.swiftUI)
                    }
                }
                .padding(.horizontal)
                Divider()
            }
            .background()
            if isPublicChat {
                Text(footer)
                    .font(.footnote)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)
                    .padding(.horizontal)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
