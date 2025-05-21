import MEGADesignToken
import SwiftUI

struct ChatRoomsEmptyCenterView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let image: Image
    let title: String
    let description: String?
    
    var body: some View {
        VStack {
            if verticalSizeClass != .compact {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .tint(TokenColors.Icon.secondary.swiftUI)
            }
            
            Text(title)
                .font(.body)
                .padding(.bottom, 5)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
            
            if let description {
                Text(description)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            }
        }
    }
}
