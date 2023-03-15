import SwiftUI

struct SingleSelectionCheckmarkView: View {
    let markedSelected: Bool
    
    private var foregroundColor: Color {
        markedSelected ? .green : Color(Colors.Photos.photoSeletionBorder.color)
    }
    
    private var backgroundView: some View {
        markedSelected ? Color.white.mask(Circle()) : nil
    }
    
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 23))
            .foregroundColor(foregroundColor)
            .background(backgroundView)
            .opacity(markedSelected ? 1.0 : 0.0)
    }
}
