import Combine
import MEGASwiftUI
import SwiftUI

struct PageTabView: View {
    @ObservedObject private var viewModel: PagerTabViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private let textForgroundRedColor = Color(Colors.General.Red.f7363D.color)
    private var tabForgroundColor: Color {
        if !viewModel.isEditing {
            return tabTextColor
        } else {
            return Color(Colors.General.Gray._515151.color)
        }
    }
    
    private var tabTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private let defaultTabFont = Font.system(.subheadline, design: .default).weight(.regular)
    private let selectedTabFont = Font.system(.subheadline, design: .default).weight(.medium)
    
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
                            .font(viewModel.selectedTab == .timeline ? selectedTabFont : defaultTabFont)
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
                            .font(viewModel.selectedTab == .album ? selectedTabFont : defaultTabFont)
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .album ? textForgroundRedColor : tabForgroundColor)
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(height: 40)
            .background(Color(Colors.Photos.pageTabForeground.color))
            .overlay(
                BottomIndicator(width: proxy.size.width, height: 2, offset: viewModel.tabOffset, color: textForgroundRedColor),
                alignment: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
