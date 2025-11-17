import MEGADesignToken
import SwiftUI

struct CameraUploadProgressEmptyRowView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.callout)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .background(TokenColors.Background.page.swiftUI)
            .padding(TokenSpacing._5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    CameraUploadProgressEmptyRowView(title: "Test")
}
