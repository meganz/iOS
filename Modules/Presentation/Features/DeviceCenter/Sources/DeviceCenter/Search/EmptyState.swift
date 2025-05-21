import MEGAAssets
import SwiftUI

struct DeviceCenterEmptyStateView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let image: String?
    let title: String
    
    var body: some View {
        VStack {
            if verticalSizeClass != .compact,
               let image {
                MEGAAssets.Image.image(named: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
            
            Text(title)
                .font(.body)
                .padding(.bottom, 5)
        }
    }
}
