import SwiftUI

public struct TagView: View {
    let tagName: String
    let tagColor: Color
    let tagTextColor: Color
    let cornerRadius: CGFloat
    let paddingInsets: EdgeInsets
    let font: Font
    
    public init(
        tagName: String,
        tagColor: Color,
        tagTextColor: Color,
        cornerRadius: CGFloat = 8,
        paddingInsets: EdgeInsets = EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8),
        font: Font = .caption2.bold()
    ) {
        self.tagName = tagName
        self.tagColor = tagColor
        self.tagTextColor = tagTextColor
        self.cornerRadius = cornerRadius
        self.paddingInsets = paddingInsets
        self.font = font
    }
    
    public var body: some View {
        Text(tagName)
            .font(font)
            .foregroundStyle(tagTextColor)
            .padding(paddingInsets)
            .background(tagColor)
            .cornerRadius(cornerRadius)
    }
}
