import MEGAAssets
import MEGADesignToken
import SwiftUI
import UIKit

struct SlideShowOptionDetailCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionDetailCellViewModel
    
    private var backgroundColor: Color {
        TokenColors.Background.page.swiftUI
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let icon = viewModel.image {
                    Image(uiImage: icon)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                
                Text(viewModel.title)
                    .font(.body)
                    .padding(.vertical, 13)
                
                Spacer()
                MEGAAssets.Image.turquoiseCheckmark
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Support.success.swiftUI)
                    .scaledToFit()
                    .opacity(viewModel.isSelected ? 1 : 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
        }
        .background(backgroundColor)
    }
}
