import Combine
import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct PageTabView: View {
    @ObservedObject private var viewModel: PagerTabViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var textForgroundRedColor: Color {
        isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : MEGAAppColor.Red._F7363D.color
    }
    
    private var bottomIndicatorColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Button.brand.swiftUI
        } else {
            colorScheme == .dark ? MEGAAppColor.Red._F30C14.color : MEGAAppColor.Red._F7363D.color
        }
    }
    
    private var tabForgroundColor: Color {
        if isDesignTokenEnabled {
            if !viewModel.isEditing {
                return tabTextColor
            } else {
                return TokenColors.Text.primary.swiftUI
            }
        } else {
            if !viewModel.isEditing {
                return tabTextColor
            } else {
                return MEGAAppColor.Gray._515151.color
            }
        }
    }
    
    private var tabTextColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.primary.swiftUI
        } else {
            colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color
        }
    }
    
    init(viewModel: PagerTabViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                HStack {
                    Button {
                        withAnimation {
                            viewModel.tabOffset = 0
                            viewModel.selectedTab = .timeline
                        }
                    } label: {
                        Text(viewModel.timeLineTitle)
                            .font(Font.system(.subheadline, design: .default).weight(.medium))
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .timeline ? textForgroundRedColor : tabForgroundColor)
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.tabOffset = proxy.size.width / 2
                            viewModel.selectedTab = .album
                        }
                        
                    } label: {
                        Text(viewModel.albumsTitle)
                            .font(Font.system(.subheadline, design: .default).weight(.medium))
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .album ? textForgroundRedColor : tabForgroundColor)
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(height: 40)
            .background(isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.photosPageTabForeground)
            .overlay(
                BottomIndicator(width: proxy.size.width, height: 1, offset: viewModel.tabOffset, color: bottomIndicatorColor),
                alignment: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
