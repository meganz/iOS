import SwiftUI

struct ChatRoomsTopRowView: View {
    let imageAsset: ImageAsset?
    let description: String
    private let discolureIndicator = "chevron.right"
    
    var body: some View {
        HStack {
            if let imageAsset, let image = Image(uiImage: UIImage(asset: imageAsset)) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            
            Text(description)
                .font(.subheadline.weight(.medium))
            
            Spacer()
            Image(systemName: discolureIndicator)
                .foregroundColor(.gray.opacity(0.6))
        }
    }
}
