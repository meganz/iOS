import MEGADesignToken
import SwiftUI

struct MeetingsListHeaderView: View {
    let title: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TokenColors.Background.surface1.swiftUI
            
            Text(title)
                .font(.footnote)
                .foregroundColor(TokenColors.Text.placeholder.swiftUI)
                .offset(CGSize(width: 16, height: -6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
    }
}
