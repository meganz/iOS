import SwiftUI

public struct TagView: View {
    let tagName: String
    let tagColor: Color
    let tagTextColor: Color
    let cornerRadius: CGFloat
    
    public init(tagName: String, tagColor: Color, tagTextColor: Color, cornerRadius: CGFloat = 8) {
        self.tagName = tagName
        self.tagColor = tagColor
        self.tagTextColor = tagTextColor
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Text(tagName)
            .font(.caption2)
            .bold()
            .foregroundStyle(tagTextColor)
            .padding(6)
            .padding(.horizontal, 2)
            .background(tagColor)
            .cornerRadius(cornerRadius)
    }
}
