import MEGADesignToken
import SwiftUI

struct NumberBadge: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 16))
            .fontWeight(.semibold)
            .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
            .background(TokenColors.Background.page.swiftUI)
            .clipShape(RoundedRectangle(cornerRadius: 13.5))
    }
}
