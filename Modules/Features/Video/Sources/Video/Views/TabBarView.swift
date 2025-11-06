import SwiftUI

struct TabBarView: View {
    @Binding var currentTab: VideosTab
    @Namespace var namespace
    let videoConfig: VideoConfig
    
    static let defaultHeight: CGFloat = 44
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    var body: some View {
        HStack {
            if interfaceOrientation.isLandscape {
                Spacer()
            }
            ForEach(VideosTab.allCases, id: \.self) { tab in
                TabBarItem(
                    currentTab: self.$currentTab,
                    namespace: namespace.self,
                    tabBarItemName: tab.title,
                    tab: tab,
                    videoConfig: videoConfig
                )
                .frame(maxWidth: orientation.isPortrait ? .infinity : 195)
            }
            if interfaceOrientation.isLandscape {
                Spacer()
            }
        }
        .frame(maxWidth: interfaceOrientation.isPortrait ? .infinity : nil)
        .edgesIgnoringSafeArea(.all)
        .background(videoConfig.colorAssets.navigationBgColor)
        .onRotate { newOrientation in
            orientation = newOrientation
        }
    }
    
    private var interfaceOrientation: UIInterfaceOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .unknown
        }
        return windowScene.interfaceOrientation
    }
}

struct TabBarItem: View {
    @Binding var currentTab: VideosTab
    let namespace: Namespace.ID
    
    var tabBarItemName: String
    var tab: VideosTab
    
    let videoConfig: VideoConfig
    
    var body: some View {
        Button(
            action: { currentTab = tab },
            label: buttonContent
        )
    }
    
    private func buttonContent() -> some View {
        ZStack(alignment: .bottom) {
            Text(tabBarItemName)
                .multilineTextAlignment(.center)
                .font(isTabActive ? .system(.subheadline).bold() : .subheadline)
                .foregroundStyle(
                    isTabActive
                    ? videoConfig.colorAssets.tabActiveIndicatorColor
                    : videoConfig.colorAssets.tabInactiveTextColor
                )
                .frame(maxHeight: .infinity, alignment: .center)
            
            Group {
                if isTabActive {
                    videoConfig.colorAssets.tabActiveIndicatorColor
                        .frame(height: 1)
                        .matchedGeometryEffect(id: "underline", in: namespace, properties: .frame)
                } else {
                    videoConfig.colorAssets.tabInactiveIndicatorColor
                        .frame(height: 1)
                }
            }
        }
        .animation(.spring(), value: self.currentTab)
        .frame(height: TabBarView.defaultHeight)
    }
    
    private var isTabActive: Bool {
        currentTab == tab
    }
}

struct Preview_TabBarView: View {
    @State private var currentTab: VideosTab = .all
    
    var body: some View {
        TabBarView(
            currentTab: $currentTab,
            videoConfig: .preview
        )
    }
}

#Preview {
    Preview_TabBarView()
}

#Preview {
    Preview_TabBarView()
        .preferredColorScheme(.dark)
}

#Preview {
    Preview_TabBarView()
        .dynamicTypeSize(.xxxLarge)
}
