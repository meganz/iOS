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
            Divider()
            HStack {
                Text(text)
                    .font(.body)
                Spacer()
                Image(uiImage: applyToAllSelected ? UIImage.checkBoxSelected : UIImage.checkBoxUnselected)
                    .resizable()
                    .frame(width: Constants.applyToAllIconSize, height: Constants.applyToAllIconSize)
            }
            Divider()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(MEGAAppColor.Black._2C2C2E.uiColor) : MEGAAppColor.White._FFFFFF.color)
        .onTapGesture {
            applyToAllSelected.toggle()
        }
    }
}
