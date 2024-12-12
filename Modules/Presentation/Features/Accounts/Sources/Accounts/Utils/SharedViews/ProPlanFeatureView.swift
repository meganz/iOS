import MEGAAssets
import MEGADesignToken
import SwiftUI

public struct ProPlanFeatureView: View {
    let image: UIImage?
    let title: String
    let message: String
    
    public var body: some View {
        HStack(spacing: 20) {
            Image(uiImage: image)?
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProPlanFeatureView(image: MEGAAssetsImageProvider.image(named: "storage"), title: "Title", message: "Message")
}
