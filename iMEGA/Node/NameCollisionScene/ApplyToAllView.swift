import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ApplyToAllView: View {
    var text: String
    @Binding var applyToAllSelected: Bool
    
    private enum Constants {
        static let applyToAllIconSize: CGFloat = 22
    }
    
    var body: some View {
        HStack {
            MEGADivider()
            HStack {
                Text(text)
                    .font(.body)
                Spacer()
                Image(uiImage: applyToAllSelected ? selectedImage : unselectedImage)
                    .resizable()
                    .frame(width: Constants.applyToAllIconSize, height: Constants.applyToAllIconSize)
            }
            MEGADivider()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background()
        .onTapGesture {
            applyToAllSelected.toggle()
        }
    }
    
    private var selectedImage: UIImage {
        MEGAAssets.UIImage.checkBoxSelectedSemantic
    }
    
    private var unselectedImage: UIImage {
        MEGAAssets.UIImage.checkBoxUnselected.withTintColorAsOriginal(TokenColors.Border.strong)
    }
}
