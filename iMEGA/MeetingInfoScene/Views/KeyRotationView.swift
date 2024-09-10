import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct KeyRotationView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                            .foregroundColor(MEGAAppColor.Gray._8E8E93.color.opacity(Constants.disclosureOpacity))
                            .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
                    } else {                        Text(rightDetail)
                            .font(.footnote)
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.mnz_grayB5B5B5()) : Color(UIColor.mnz_gray848484()))
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
