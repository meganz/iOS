import SwiftUI

public struct CheckMarkView: View {
    let markedSelected: Bool
    let foregroundColor: Color
    let showBorder: Bool
    let borderColor: Color
    
    public init(markedSelected: Bool,
                foregroundColor: Color,
                showBorder: Bool = true,
                borderColor: Color = Color.white) {
        self.markedSelected = markedSelected
        self.foregroundColor = foregroundColor
        self.showBorder = showBorder
        self.borderColor = borderColor
    }
    
    private var imageName: String {
        markedSelected ? "checkmark.circle.fill" : "circle"
    }
    
    private var backgroundView: some View {
        markedSelected && showBorder ? Color.white.mask(Circle()) : nil
    }
    
    public var body: some View {
        Image(
            systemName: imageName)
            .font(.system(size: 23))
            .foregroundColor(foregroundColor)
            .background(backgroundView)
    }
}
