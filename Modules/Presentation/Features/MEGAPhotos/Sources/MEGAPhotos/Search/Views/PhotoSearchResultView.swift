import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

struct PhotoSearchResultView: View {
    let photos: [PhotoSearchResultItemViewModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(Strings.Localizable.Photos.SearchResults.Media.Section.title)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 6)
            
            List(photos) { photoItemViewModel in
                PhotoSearchResultItemView(viewModel: photoItemViewModel)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listStyle(.plain)
        .background(TokenColors.Background.page.swiftUI)
    }
}
