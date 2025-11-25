import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct CameraUploadProgressSkeletonHeaderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
            .frame(width: 154, height: 9)
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            .shimmering()
    }
}

struct CameraUploadProgressSkeletonRowView: View {
    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
                .frame(width: 32, height: 32)
            
            RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
                .frame(height: 9)
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .frame(maxWidth: .infinity)
        .shimmering()
        .pageBackground()
    }
}

#Preview {
    CameraUploadProgressSkeletonHeaderView()
    CameraUploadProgressSkeletonRowView()
}
