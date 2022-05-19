import SwiftUI
import Combine

struct PageTabView: View {
    @ObservedObject private var viewModel: PagerTabViewModel
    @Environment(\.colorScheme) var colorScheme
    
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
                            .foregroundColor(viewModel.selectedTab == .timeline ? .red : colorScheme == .dark ? .white : .black)
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.tabOffset = proxy.size.width / 2
                            viewModel.selectedTab = .album
                        }
                        
                    } label: {
                        Text(viewModel.albumsTitle)
                            .frame(maxWidth: proxy.size.width, alignment: .center)
                            .foregroundColor(viewModel.selectedTab == .album ? .red : colorScheme == .dark ? .white : .black)
                    }
                }
                .padding(.top, 10)
                
                BottomIndicator(width: proxy.size.width, height: 2, offset: viewModel.tabOffset, color: .red)
            }
            .background(Color(Colors.Photos.pageTabForeground.color))
        }
    }
}
