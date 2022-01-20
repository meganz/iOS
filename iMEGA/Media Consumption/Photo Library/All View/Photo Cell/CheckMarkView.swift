import SwiftUI

struct CheckMarkView: View {
    var markedSelected: Bool
    
    private var imageName: String {
        markedSelected ? "checkmark.circle.fill" : "circle"
    }
    
    private var foregroundColor: Color {
        markedSelected ? .green : Color(Colors.Photos.photoSeletionBorder.color)
    }
    
    private var backgroundView: some View {
        markedSelected ? Color.white.mask(Circle()) : nil
    }
    
    var body: some View {
        Image(
            systemName: imageName)
            .font(.system(size: 23))
            .foregroundColor(foregroundColor)
            .background(backgroundView)
    }
}
