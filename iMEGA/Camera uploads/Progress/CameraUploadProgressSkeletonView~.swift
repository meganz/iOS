import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct CameraUploadProgressSkeletonView: View {
    private let placeholderCount = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._7) {
            sectionView
            sectionView
        }
        .padding(.horizontal, TokenSpacing._5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background()
    }
    
    private var sectionView: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            headerView
            itemsView
        }
        .shimmering()
    }
    
    private var headerView: some View {
        RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
            .frame(width: 154, height: 9)
    }
    
    private var itemsView: some View {
        VStack(spacing: TokenSpacing._3) {
            ForEach(0..<placeholderCount, id: \.self) { _ in
                itemPlaceholder
            }
        }
    }
    
    private var itemPlaceholder: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
                .frame(width: 32, height: 32)
            
            RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
                .frame(height: 9)
        }
        .background()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CameraUploadProgressSkeletonView()
}
