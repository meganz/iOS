import MEGADesignToken
import SwiftUI

struct MeetingsListHeaderView: View {
    let title: String
    
    private var backgroundColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Background.surface1.swiftUI
        } else {
            UIColor.chatListSectionBackground.swiftUI
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundColor
            
            Text(title)
                .font(.footnote)
                .foregroundColor(
                    isDesignTokenEnabled ? TokenColors.Text.placeholder.swiftUI : UIColor.chatListSectionTitle.swiftUI
                )
                .offset(CGSize(width: 16, height: -6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
    }
}
