import SwiftUI

struct MeetingsListHeaderView: View {
    let title: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.chatListSectionBackground
            
            Text(title)
                .font(.footnote)
                .foregroundColor(Color.chatListSectionTitle)
                .offset(CGSize(width: 16, height: -6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
    }
}
