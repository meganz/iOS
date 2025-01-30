import SwiftUI

public struct PageTabView<ID: Hashable & Identifiable>: View {
    public struct TabItem: Identifiable {
        public let id: ID
        let title: String
        let content: AnyView
        
        public init<Content: View>(id: ID, title: String, @ViewBuilder content: @escaping () -> Content) {
            self.id = id
            self.title = title
            self.content = AnyView(content())
        }
    }
    
    private let tabs: [TabItem]
    @Binding private var selectedTab: ID
    private let selectedTextForegroundColor: Color
    private let textForegroundColor: Color
    private let tabSelectionIndicatorColor: Color
    private let backgroundColor: Color
    
    public init(
        tabs: [TabItem],
        selectedTab: Binding<ID>,
        selectedTextForegroundColor: Color,
        textForegroundColor: Color,
        tabSelectionIndicatorColor: Color,
        backgroundColor: Color
    ) {
        self.tabs = tabs
        self._selectedTab = selectedTab
        self.selectedTextForegroundColor = selectedTextForegroundColor
        self.textForegroundColor = textForegroundColor
        self.tabSelectionIndicatorColor = tabSelectionIndicatorColor
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            tabButtons
            
            TabView(selection: $selectedTab) {
                ForEach(tabs) { tab in
                    tab.content
                        .tag(tab.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    private var tabButtons: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab.id
                    }
                } label: {
                    Text(tab.title)
                        .foregroundStyle(selectedTab == tab.id ? selectedTextForegroundColor : textForegroundColor)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 44)
        .background(backgroundColor)
        .overlay(
            bottomSelectionIndicator,
            alignment: .bottom
        )
    }
    
    private var bottomSelectionIndicator: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom) {
                Spacer()
                    .frame(width: geometry.size.width / CGFloat(tabs.count) * CGFloat(tabs.firstIndex(where: { $0.id == selectedTab }) ?? 0))
                
                Rectangle()
                    .fill(tabSelectionIndicatorColor)
                    .frame(width: geometry.size.width / CGFloat(tabs.count))
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: 1)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height - 1)
        }
    }
}

#Preview {
    struct PageTabViewPreview: View {
        enum Tab: Identifiable {
            var id: Self { self }
            case one
            case two
        }
        @State var selectedTab = Tab.two
        
        var body: some View {
            PageTabView(
                tabs: [
                    .init(id: Tab.one,
                          title: "Test 1") {
                              Text("Tab 1")
                          },
                    .init(id: Tab.two,
                          title: "Test 2") {
                              Text("Tab 2")
                          }
                ],
                selectedTab: $selectedTab,
                selectedTextForegroundColor: .red,
                textForegroundColor: .black,
                tabSelectionIndicatorColor: .red,
                backgroundColor: .white
            )
        }
    }
    
    return PageTabViewPreview()
}
