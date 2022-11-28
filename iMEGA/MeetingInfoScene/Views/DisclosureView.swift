import SwiftUI

struct DisclosureView: View {
    let image: String?
    let text: String
    let action: (() -> Void)
    @Environment(\.layoutDirection) var layoutDirection

    private let discolureIndicator = "chevron.right"

    var body: some View {
        VStack {
            Divider()
            HStack {
                if let image {
                    Image(image)
                }
                Text(text)
                    .font(.body)
                Spacer()
                Image(systemName: discolureIndicator)
                    .foregroundColor(.gray.opacity(0.6))
                    .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
            }
            .padding(.horizontal)
            Divider()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
