import SwiftUI

struct DetailDisclosureView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let disclosureOpacity: CGFloat = 0.6
        static let discolureIndicator = "chevron.right"
    }
    
    let text: String
    let detail: String?
    let requiresPadding: Bool
    let verticalAlignment: VerticalAlignment
    let action: (() -> Void)
    
    init(
        text: String,
        detail: String? = nil,
        requiresPadding: Bool = true,
        verticalAlignment: VerticalAlignment = .center,
        action: @escaping (() -> Void)
    ) {
        self.text = text
        self.detail = detail
        self.requiresPadding = requiresPadding
        self.verticalAlignment = verticalAlignment
        self.action = action
    }

    var body: some View {
        VStack {
            if requiresPadding {
                content()
                    .padding(.horizontal)
            } else {
                content()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
    private func content() -> some View {
        HStack(alignment: verticalAlignment) {
            Text(text)
                .font(.body)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundColor(colorScheme == .dark ? MEGAAppColor.Gray._EBEBF5.color.opacity(Constants.disclosureOpacity) : MEGAAppColor.Gray._3C3C43.color.opacity(Constants.disclosureOpacity))
            }
            Image(systemName: Constants.discolureIndicator)
                .foregroundColor(MEGAAppColor.Gray._8E8E93.color.opacity(Constants.disclosureOpacity))
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
    }
}
