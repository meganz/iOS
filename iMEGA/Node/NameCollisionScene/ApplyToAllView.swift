import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ApplyToAllView: View {
    @Environment(\.colorScheme) private var colorScheme

    var text: String
    @Binding var applyToAllSelected: Bool
    
    private enum Constants {
        static let applyToAllIconSize: CGFloat = 22
    }
    
    var body: some View {
        HStack {
            MEGADivider(isDesignTokenEnabled: isDesignTokenEnabled)
            HStack {
                Text(text)
                    .font(.body)
                Spacer()
                Image(uiImage: applyToAllSelected ? selectedImage : unselectedImage)
                    .resizable()
                    .frame(width: Constants.applyToAllIconSize, height: Constants.applyToAllIconSize)
            }
            MEGADivider(isDesignTokenEnabled: isDesignTokenEnabled)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .designTokenBackground(
            isDesignTokenEnabled,
            legacyColor: colorScheme == .dark ? Color(MEGAAppColor.Black._2C2C2E.uiColor) : MEGAAppColor.White._FFFFFF.color
        )
        .onTapGesture {
            applyToAllSelected.toggle()
        }
    }
    
    private var selectedImage: UIImage {
        isDesignTokenEnabled ? UIImage.checkBoxSelectedSemantic : UIImage.checkBoxSelected
    }
    
    private var unselectedImage: UIImage {
        isDesignTokenEnabled ? UIImage.checkBoxUnselected.withTintColorAsOriginal(TokenColors.Border.strong)  : UIImage.checkBoxUnselected
    }
}
