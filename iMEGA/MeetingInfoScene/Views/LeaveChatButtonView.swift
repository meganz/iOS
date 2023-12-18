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
                    .foregroundColor(MEGAAppColor.Red._F30C14.color)
            }
            Divider()
        }
        .frame(minHeight: Constants.viewHeight)
        .background(colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
    }
}
