import ContentLibraries
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct VisualMediaSearchLoadingView: View {
    private let isActive: Bool
    
    init(isActive: Bool = true) {
        self.isActive = isActive
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AlbumSearchResultLoadingView(isActive: isActive)
            
            PhotoSearchResultLoadingView(isActive: isActive)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background()
    }
}

private struct AlbumSearchResultLoadingView: View {
    private let placeholderCount = 20
    private let isActive: Bool
    
    init(isActive: Bool) {
        self.isActive = isActive
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlaceHolderLoadingHeaderView(
                title: Strings.Localizable.CameraUploads.Albums.title)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [.init(.fixed(172))], spacing: 12) {
                    ForEach(0..<placeholderCount, id: \.self) { _ in
                        albumPlaceholder
                    }
                }
                .shimmering(active: isActive)
            }
            .padding(.vertical, 8)
            .padding(.leading, 16)
            .animation(.smooth, value: isActive)
        }
    }
    
    private var albumPlaceholder: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .aspectRatio(contentMode: .fill)
                .padding(.bottom, 8)
            
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .frame(width: 80, height: 12, alignment: .leading)
                .padding(.bottom, 4)
            
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .frame(width: 32, height: 8, alignment: .leading)
        }
        .frame(width: 140, height: 172)
    }
}

private struct PlaceHolderLoadingHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

private struct PhotoSearchResultLoadingView: View {
    private let placeholderCount = 30
    private let isActive: Bool
    
    init(isActive: Bool) {
        self.isActive = isActive
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            PlaceHolderLoadingHeaderView(title: Strings.Localizable.Photos.SearchResults.Media.Section.title)
            
            List(0..<placeholderCount, id: \.self) { _ in
                itemPlaceholder
                    .listRowBackground(TokenColors.Background.page.swiftUI)
            }
            .shimmering(active: isActive)
        }
        .listStyle(.plain)
        .background()
    }
    
    private var itemPlaceholder: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .frame(width: 40, height: 40)
            
            RoundedRectangle(cornerRadius: 12.5, style: .continuous)
                .frame(width: 158, height: 12)
        }
        .background()
    }
}

#Preview {
    VisualMediaSearchLoadingView(isActive: true)
}
