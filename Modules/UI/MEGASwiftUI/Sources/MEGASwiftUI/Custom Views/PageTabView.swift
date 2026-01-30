import SwiftUI

public struct PageTabItem<ID: Hashable & Identifiable>: Identifiable {
    public let id: ID
    public let title: String

    public init(id: ID, title: String) {
        self.id = id
        self.title = title
    }
}

public struct PageTabView<ID: Hashable & Identifiable, Content: View>: View {
    public typealias TabItem = PageTabItem<ID>
    
    private let tabs: [TabItem]
    @Binding private var selectedTab: ID
    private let selectedTextForegroundColor: Color
    private let textForegroundColor: Color
    private let tabSelectionIndicatorColor: Color
    private let backgroundColor: Color
    @Binding private var isTabSwitchingDisabled: Bool
    @ViewBuilder private let content: (ID) -> Content

    public init(
        tabs: [TabItem],
        selectedTab: Binding<ID>,
        selectedTextForegroundColor: Color,
        textForegroundColor: Color,
        tabSelectionIndicatorColor: Color,
        backgroundColor: Color,
        isTabSwitchingDisabled: Binding<Bool>,
        @ViewBuilder content: @escaping (ID) -> Content
    ) {
        self.tabs = tabs
        self._selectedTab = selectedTab
        self.selectedTextForegroundColor = selectedTextForegroundColor
        self.textForegroundColor = textForegroundColor
        self.tabSelectionIndicatorColor = tabSelectionIndicatorColor
        self.backgroundColor = backgroundColor
        self._isTabSwitchingDisabled = isTabSwitchingDisabled
        self.content = content
    }
    
    public init(
        tabs: [TabItem],
        selectedTab: Binding<ID>,
        selectedTextForegroundColor: Color,
        textForegroundColor: Color,
        tabSelectionIndicatorColor: Color,
        backgroundColor: Color,
        isTabSwitchingDisabled: Bool = false,
        @ViewBuilder content: @escaping (ID) -> Content
    ) {
        self.init(
            tabs: tabs,
            selectedTab: selectedTab,
            selectedTextForegroundColor: selectedTextForegroundColor,
            textForegroundColor: textForegroundColor,
            tabSelectionIndicatorColor: tabSelectionIndicatorColor,
            backgroundColor: backgroundColor,
            isTabSwitchingDisabled: .constant(isTabSwitchingDisabled),
            content: content
        )
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            tabButtons

            TabView(selection: $selectedTab) {
                ForEach(tabs) { tab in
                    content(tab.id)
                        .id(tab.id)
                        .tag(tab.id)
                        .gesture(isTabSwitchingDisabled ? DragGesture() : nil)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    private var tabButtons: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    guard !isTabSwitchingDisabled else { return }
                    withAnimation {
                        selectedTab = tab.id
                    }
                } label: {
                    Text(tab.title)
                        .foregroundStyle(selectedTab == tab.id ? selectedTextForegroundColor : textForegroundColor)
                        .frame(maxWidth: .infinity)
                }
                .disabled(isTabSwitchingDisabled)
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
        @State var isTabSwitchingDisabled = false
        
        var body: some View {
            PageTabView(
                tabs: [
                    .init(id: Tab.one, title: "Test 1"),
                    .init(id: Tab.two, title: "Test 2")
                ],
                selectedTab: $selectedTab,
                selectedTextForegroundColor: .red,
                textForegroundColor: .black,
                tabSelectionIndicatorColor: .red,
                backgroundColor: .white,
                isTabSwitchingDisabled: $isTabSwitchingDisabled
            ) { tab in
                switch tab {
                case .one:
                    Text("Tab 1")
                case .two:
                    Text("Tab 2")
                }
            }
        }
    }
    
    return PageTabViewPreview()
}
