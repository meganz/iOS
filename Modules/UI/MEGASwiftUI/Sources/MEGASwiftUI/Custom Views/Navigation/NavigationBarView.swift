import SwiftUI

/**
 SwiftUI NavigationView's navigation bar sometimes doesn't work correctly for light and dark mode when the screen is active. iOS 14, 15, 16 issues.
 To tackle that problem, NavigationBarView is used. 
 */
public struct NavigationBarView <Leading: View, Trailing: View, Center: View>: View {
    private let leading: () -> Leading?
    private let trailing: () -> Trailing?
    private let center: () -> Center
    private let leadingWidth: Double
    private let trailingWidth: Double
    private let backgroundColor: Color
    
    public init(
        @ViewBuilder leading: @escaping () -> Leading? = { nil },
        @ViewBuilder trailing: @escaping () -> Trailing? = { nil },
        @ViewBuilder center: @escaping () -> Center,
        leadingWidth: Double = 100,
        trailingWidth: Double = 100,
        backgroundColor: Color
    ) {
        self.leading = leading
        self.trailing = trailing
        self.center = center
        self.leadingWidth = leadingWidth
        self.trailingWidth = trailingWidth
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        HStack {
            HStack {
                leading()
                Spacer()
            }.frame(width: leadingWidth)
            
            Spacer()
            center()
            Spacer()
            
            HStack {
                Spacer()
                trailing()
            }
            .frame(width: trailingWidth)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(backgroundColor.ignoresSafeArea(edges: [.top, .leading, .trailing]))
    }
}

#Preview {
    Group {
        NavigationBarView(
            leading: { Button(action: {}, label: { Text("Button 1") }) },
            trailing: { Button(action: {}, label: { Text("Button 2") }) },
            center: { NavigationTitleView(title: "Title") },
            backgroundColor: Color.white
        )
        
        NavigationBarView(
            leading: { Button(action: {}, label: { Text("Button 1") }) },
            trailing: { Button(action: {}, label: { Text("Button 2") }) },
            center: { NavigationTitleView(title: "A long navigation title") },
            leadingWidth: 75,
            trailingWidth: 75,
            backgroundColor: Color.white
        )
    }
    .preferredColorScheme(.light)
}

#Preview {
    NavigationBarView(leading: {
        Button(action: {}, label: { Text("Button 1") })
    }, trailing: {
        Button(action: {}, label: { Text("Button 2") })
    }, center: {
        NavigationTitleView(title: "Title")
    }, backgroundColor: Color.black
    )
    .preferredColorScheme(.dark)
}
