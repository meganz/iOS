import MEGADesignToken
import SwiftUI

struct NewChatRoomsEmptyCenterView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let state: ChatRoomsEmptyCenterViewState
    
    var body: some View {
        VStack {
            if verticalSizeClass != .compact {
                Image(state.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .tint(TokenColors.Icon.secondary.swiftUI)
            }
            
            Text(state.title)
                .font(.headline.bold())
                .padding(.bottom, 5)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
            
            if  let description = state.description {
                joinedWithLink(
                    text: description,
                    link: state.descriptionLink
                )
                // line below is needed for tappable link to work
                    .textSelection(.enabled)
                    .environment(\.openURL, OpenURLAction { _ in
                        state.linkTapped?()
                        return .handled
                    })
                    .tint(TokenColors.Text.secondary.swiftUI)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)
            }
        }
    }
    
    /// simple implementation to (conditionally) handle tappable inline links (using OpenURLAction)  with underline
    private func joinedWithLink(
        text: String,
        link: String?
    ) -> Text {
        if let link {
            Text(LocalizedStringKey(text)) + Text(" ") + Text(LocalizedStringKey(link)).underline()
        } else {
            Text(LocalizedStringKey(text))
        }
    }
}
