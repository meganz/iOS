import SwiftUI

struct MeetingsListHeaderView: View {
    let title: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MEGAAppColor.Chat.chatListSectionBackground.color
            
            Text(title)
                .font(.footnote)
                .foregroundColor(MEGAAppColor.Chat.chatListSectionTitle.color)
                .offset(CGSize(width: 16, height: -6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
    }
}
