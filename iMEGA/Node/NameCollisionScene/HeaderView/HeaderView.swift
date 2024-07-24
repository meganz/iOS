import MEGADesignToken
import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: HeaderViewModel
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 12
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            HStack {
                Text(viewModel.titleComponents[0])
                    .font(.subheadline) +
                Text(viewModel.titleComponents[1])
                    .font(.subheadline)
                    .bold() +
                Text(viewModel.titleComponents[2])
                    .font(.subheadline)
            }
            .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
        }
        .frame(maxWidth: .infinity)
    }
}
