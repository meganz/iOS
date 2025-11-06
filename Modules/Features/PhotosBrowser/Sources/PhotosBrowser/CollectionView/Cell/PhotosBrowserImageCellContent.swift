import MEGADesignToken
import MEGADomain
import SwiftUI

struct PhotosBrowserImageCellContent: View {
    @StateObject var viewModel: PhotosBrowserImageCellContentViewModel
    
    var body: some View {
        VStack {
            Text("\(viewModel.entity.name)")
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .background(TokenColors.Background.page.swiftUI)
    }
}
