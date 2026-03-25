import MEGAAssets
import MEGADesignToken
import SwiftUI

public struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        Button {
            dismiss()
        } label: {
            Image(uiImage: MEGAAssets.UIImage.backArrow)
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .padding(.horizontal, TokenSpacing._3)
                .padding(.vertical, TokenSpacing._2)
        }
    }
}
