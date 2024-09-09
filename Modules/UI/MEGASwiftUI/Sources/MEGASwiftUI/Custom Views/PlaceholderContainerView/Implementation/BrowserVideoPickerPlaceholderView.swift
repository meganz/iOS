import SwiftUI

/// A placeholder view dedicated for `BrowserActionSelectVideo` used in `BrowserViewController`
public struct BrowserVideoPickerPlaceholderView: View {
    
    public init() {}
    
    public var body: some View {
        PlaceholderContentView(
            placeholderRow: placeholderRowView,
            itemCount: 15
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
    }
    
    private var placeholderRowView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 112, height: 16)
                
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 175, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .shimmering()
    }
}

#Preview {
    BrowserVideoPickerPlaceholderView()
}

#Preview {
    BrowserVideoPickerPlaceholderView()
        .preferredColorScheme(.dark)
}
