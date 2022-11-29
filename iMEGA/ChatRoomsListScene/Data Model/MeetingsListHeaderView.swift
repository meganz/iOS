import SwiftUI

@available(iOS 14.0, *)
struct MeetingsListHeaderView: View {
    let title: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color(Colors.Chat.Listing.sectionBackground.color)
            
            Text(title)
                .font(.footnote)
                .foregroundColor(Color(Colors.Chat.Listing.sectionTitle.color))
                .offset(CGSize(width: 16, height: -6))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
    }
}
