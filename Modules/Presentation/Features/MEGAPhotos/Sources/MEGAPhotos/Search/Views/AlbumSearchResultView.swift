import ContentLibraries
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGAUIComponent
import SwiftUI

struct AlbumSearchResultView: View {
    @StateObject var viewModel: AlbumSearchResultViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.Localizable.CameraUploads.Albums.title)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 6)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [.init(.fixed(182))], spacing: 12) {
                    ForEach(Array(viewModel.albums.enumerated()), id: \.element.id) { index, viewModel in
                        AlbumCell(viewModel: viewModel)
                            .frame(width: 140)
                            .padding(.leading, index == 0 ? 16 : 0)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(height: 198)
        }
    }
}

#Preview {
    AlbumSearchResultView(viewModel: .init(albums: [], searchText: .constant("")))
}
