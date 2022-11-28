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

    var body: some View {
        VStack {
            Divider()
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                if isPublicChat {
                    Image(systemName: discolureIndicator)
                        .foregroundColor(.gray.opacity(0.6))
                        .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
                } else {
                    Text(rightDetail)
                        .font(.footnote)
                        .foregroundColor(colorScheme == .dark ? Color(UIColor.mnz_grayB5B5B5()) : Color(UIColor.mnz_gray848484()))
                }
            }
            .padding(.horizontal)
            Divider()
            if isPublicChat {
                Text(footer)
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.mnz_gray3C3C43()).opacity(0.6))
                    .padding(.horizontal)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
