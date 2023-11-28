import SwiftUI

struct LeaveChatButtonView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let viewHeight: CGFloat = 44
    }
    
    let text: String
    let action: (() -> Void)

    var body: some View {
        VStack {
            Divider()
            Button {
                action()
            } label: {
                Text(text)
                    .padding(.horizontal)
                    .foregroundColor(Color(UIColor.redF30C14))
            }
            Divider()
        }
        .frame(minHeight: Constants.viewHeight)
        .background(colorScheme == .dark ? Color(.black1C1C1E) : .white)
    }
}
