import Combine
import MEGASwiftUI
import SwiftUI

struct PageTabView: View {
    @ObservedObject private var viewModel: PagerTabViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private let textForgroundRedColor = MEGAAppColor.Red._F7363D.color
    private var tabForgroundColor: Color {
        if !viewModel.isEditing {
            return tabTextColor
        } else {
            return MEGAAppColor.Gray._515151.color
        }
    }
    
    private var tabTextColor: Color {
        colorScheme == .dark ? .white : MEGAAppColor.Black._000000.color
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
            .background(Color.photosPageTabForeground)
            .overlay(
                BottomIndicator(width: proxy.size.width, height: 1, offset: viewModel.tabOffset, color: textForgroundRedColor),
                alignment: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
