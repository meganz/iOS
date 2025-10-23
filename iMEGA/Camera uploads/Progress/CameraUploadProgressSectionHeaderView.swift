import MEGADesignToken
import SwiftUI

struct CameraUploadProgressSectionHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pageBackground()
    }
}

#Preview {
    CameraUploadProgressSectionHeaderView(title: "Test")
}
