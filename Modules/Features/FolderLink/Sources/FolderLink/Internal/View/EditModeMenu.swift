import MEGAAssets
import MEGAL10n
import SwiftUI

struct EditModeMenu: View {
    @Binding var editMode: EditMode
    
    var body: some View {
        Button {
            editMode = .active
        } label: {
            Text(Strings.Localizable.select)
            Image(uiImage: MEGAAssets.UIImage.selectItem)
        }
    }
}
