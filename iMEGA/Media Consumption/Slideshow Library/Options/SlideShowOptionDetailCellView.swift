import MEGADesignToken
import SwiftUI
import UIKit

struct SlideShowOptionDetailCellView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: SlideShowOptionDetailCellViewModel
    
    private var backgroundColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Background.page.swiftUI
        } else {
            colorScheme == .dark ? MEGAAppColor.Black._2C2C2E.color : MEGAAppColor.White._FFFFFF.color
        }
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
                Image(uiImage: UIImage.turquoiseCheckmark)
                    .renderingMode(.template)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : .primary)
                    .scaledToFit()
                    .opacity(viewModel.isSelected ? 1 : 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
        }
        .background(backgroundColor)
    }
}
