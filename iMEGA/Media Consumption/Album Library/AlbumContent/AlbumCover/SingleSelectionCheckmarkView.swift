import SwiftUI

struct SingleSelectionCheckmarkView: View {
    let markedSelected: Bool
    
    private var foregroundColor: Color {
        markedSelected ? MEGAAppColor.Green._34C759.color : Color.photosPhotoSeletionBorder
    }
    
    private var backgroundView: some View {
        markedSelected ? MEGAAppColor.White._FFFFFF.color.mask(Circle()) : nil
    }
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 23))
            .foregroundColor(foregroundColor)
            .background(backgroundView)
            .opacity(markedSelected ? 1.0 : 0.0)
    }
}
