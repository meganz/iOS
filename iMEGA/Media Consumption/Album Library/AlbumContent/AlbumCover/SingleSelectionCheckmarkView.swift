import MEGADesignToken
import SwiftUI

struct SingleSelectionCheckmarkView: View {
    let markedSelected: Bool
    
    private var foregroundStyle: Color {
        if isDesignTokenEnabled {
            markedSelected ? TokenColors.Support.success.swiftUI : TokenColors.Icon.onColor.swiftUI
        } else {
            markedSelected ? UIColor.green34C759.swiftUI : UIColor.photosPhotoSeletionBorder.swiftUI
        }
    }
    
    private var backgroundView: some View {
        markedSelected ? UIColor.whiteFFFFFF.swiftUI.mask(Circle()) : nil
    }
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 23))
            .foregroundStyle(foregroundStyle)
            .background(backgroundView)
            .opacity(markedSelected ? 1.0 : 0.0)
    }
}
