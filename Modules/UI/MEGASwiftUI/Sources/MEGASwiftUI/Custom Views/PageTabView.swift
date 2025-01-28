import SwiftUI

public struct PageTabView: View {
    public struct TabItem {
        let title: String
        let content: AnyView
        
        public init<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) {
            self.title = title
            self.content = AnyView(content())
        }
    }
    private let tabs: [TabItem]
    @State private var selectedTab: Int
    private let selectedTextForegroundColor: Color
    private let textForegroundColor: Color
    private let tabSelectionIndicatorColor: Color
    private let backgroundColor: Color
    
    public init(
        tabs: [TabItem],
        selectedTab: Int = 0,
        selectedTextForegroundColor: Color,
        textForegroundColor: Color,
        tabSelectionIndicatorColor: Color,
        backgroundColor: Color
    ) {
        self.tabs = tabs
        self.selectedTab = min(max(selectedTab, 0), tabs.count - 1)
        self.selectedTextForegroundColor = selectedTextForegroundColor
        self.textForegroundColor = textForegroundColor
        self.tabSelectionIndicatorColor = tabSelectionIndicatorColor
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button {
                        withAnimation {
                            selectedTab = index
                        }
                    } label: {
                        Text(tabs[index].title)
                            .foregroundStyle(selectedTab == index ? selectedTextForegroundColor : textForegroundColor)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 44)
            .background(backgroundColor)
            .overlay(
                GeometryReader { geometry in
                    HStack(alignment: .bottom) {
                        Spacer()
                            .frame(width: geometry.size.width / CGFloat(tabs.count) * CGFloat(selectedTab))
                        
                        Rectangle()
                            .fill(tabSelectionIndicatorColor)
                            .frame(width: geometry.size.width / CGFloat(tabs.count))
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: 1)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - 1)
                },
                alignment: .bottom
            )
            
            TabView(selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    tabs[index].content
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

#Preview {
    PageTabView(
        tabs: [
            .init(title: "Test 1") {
                Text("Tab 1")
            },
            .init(title: "Test 2") {
                Text("Tab 2")
            }
        ],
        selectedTextForegroundColor: .red,
        textForegroundColor: .black,
        tabSelectionIndicatorColor: .red,
        backgroundColor: .white
    )
}
