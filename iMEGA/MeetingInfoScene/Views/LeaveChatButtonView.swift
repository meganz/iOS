import MEGADesignToken
import MEGASwiftUI
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
                    .foregroundColor(buttonTextColor)
            }
            Divider()
        }
        .frame(minHeight: Constants.viewHeight)
        .designTokenBackground(isDesignTokenEnabled, legacyColor: legacyBackground)   
    }
    
    private var buttonTextColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.error.swiftUI
        } else {
            MEGAAppColor.Red._F30C14.color
        }
    }
    
    private var legacyBackground: Color {
        colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color
    }
}
