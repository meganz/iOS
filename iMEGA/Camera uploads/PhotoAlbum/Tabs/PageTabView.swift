import SwiftUI
import Combine

struct PageTabView: View {
    @ObservedObject private var viewModel: PagerTabViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var albumForgroundColor: Color {
        if !viewModel.isEditing {
            return timelineForgroundColor
        } else {
            return Color(Colors.General.Gray._515151.color)
        }
    }
    
    private var timelineForgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    init(viewModel: PagerTabViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 10) {
                HStack() {
                    Button {
                        withAnimation {
                            viewModel.tabOffset = 0
                            viewModel.selectedTab = .timeline
                        }
                    } label: {
                        Text(viewModel.timeLineTitle)
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .timeline ? .red : timelineForgroundColor)
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.tabOffset = proxy.size.width / 2
                            viewModel.selectedTab = .album
                        }
                        
                    } label: {
                        Text(viewModel.albumsTitle)
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .album ? .red : albumForgroundColor)
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(maxHeight: 35)
            .background(Color(Colors.Photos.pageTabForeground.color))
            .overlay(
                BottomIndicator(width: proxy.size.width, height: 2, offset: viewModel.tabOffset, color: .red),
                alignment: .bottom
            )
        }
    }
}
