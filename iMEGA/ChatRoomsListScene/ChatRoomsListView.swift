import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomsListView: View {
    @ObservedObject var viewModel: ChatRoomsListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ChatTabsSelectorView(chatViewMode: viewModel.chatViewMode) { mode in
                viewModel.selectChatMode(mode)
            }
            .ignoresSafeArea()
            
            if let activeCallViewModel = viewModel.activeCallViewModel {
                ChatRoomActiveCallView(viewModel: activeCallViewModel)
            }
            
            if viewModel.isConnectedToNetwork == false {
                ChatRoomsEmptyView(emptyViewState: viewModel.noNetworkEmptyViewState())
            } else {
                content()
            }
            
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: viewModel.bottomViewHeight)
        }
        .onAppear {
            viewModel.loadChatRoomsIfNeeded()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        viewModel.updateMeetingListFrame(geo.frame(in: .global))
                    }
                    .onChange(of: geo.frame(in: .global)) { _ in
                        viewModel.updateMeetingListFrame(geo.frame(in: .global))
                    }
            }
        )
        .overlay(
            TipView(tip: viewModel.makeCreateMeetingTip(),
                    width: 230,
                    contentOffsetX: -90)
            .offset(x: viewModel.createMeetingTipOffsetX)
            .opacity(viewModel.presentingCreateMeetingTip ? 1 : 0)
            , alignment: .top
        )
        .overlay(
            TipView(tip: viewModel.makeStartMeetingTip(),
                    arrowDirection: viewModel.startMeetingTipArrowDirection)
                .offset(x: 50, y: viewModel.startMeetingTipOffsetY ?? 0)
                .opacity(viewModel.presentingStartMeetingTip ? 1 : 0)
            , alignment: viewModel.startMeetingTipArrowDirection == .up ? .top : .bottom
        )
        .overlay(
            TipView(tip: viewModel.makeRecurringMeetingTip(),
                    arrowDirection: viewModel.recurringMeetingTipArrowDirection)
                .offset(x: 50, y: viewModel.recurringMeetingTipOffsetY ?? 0)
                .opacity(viewModel.presentingRecurringMeetingTip ? 1 : 0)
            , alignment: viewModel.recurringMeetingTipArrowDirection == .up ? .top : .bottom
        )
    }
    
    @ViewBuilder
    private func searchBarView() -> some View {
        if #available(iOS 15.0, *) {
            SearchBarView(
                text: $viewModel.searchText,
                isEditing: $viewModel.isSearchActive,
                placeholder: Strings.Localizable.search,
                cancelTitle: Strings.Localizable.cancel)
            .listRowSeparator(.hidden)
        } else {
            SearchBarView(
                text: $viewModel.searchText,
                isEditing: $viewModel.isSearchActive,
                placeholder: Strings.Localizable.search,
                cancelTitle: Strings.Localizable.cancel)
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        if viewModel.chatViewMode == .chats {
            if let chatRooms = viewModel.displayChatRooms {
                List {
                    if viewModel.shouldShowSearchBar {
                        searchBarView()
                    }
                    
                    if chatRooms.isNotEmpty {
                        if !viewModel.isSearchActive, let contactsOnMega = viewModel.contactsOnMegaViewState {
                            ChatRoomsTopRowView(state: contactsOnMega)
                                .onTapGesture {
                                    contactsOnMega.action()
                                }
                                .listRowInsets(EdgeInsets())
                                .padding(10)
                        }
                        
                        ForEach(chatRooms) { chatRoom in
                            ChatRoomView(viewModel: chatRoom)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
                .listStyle(.plain)
                .overlay(
                    VStack {
                        if viewModel.isChatRoomEmpty {
                            ChatRoomsEmptyView(emptyViewState: viewModel.isSearchActive ? viewModel.searchEmptyViewState() : viewModel.emptyChatRoomsViewState())
                        }
                    }
                    , alignment: .center
                )
                .edgesIgnoringSafeArea([.top, .bottom])
            } else {
                LoadingSpinner()
            }
        } else {
            if let futureMeetings = viewModel.displayFutureMeetings,
               let pastMeetings = viewModel.displayPastMeetings {
                List {
                    if viewModel.shouldShowSearchBar {
                        searchBarView()
                    }
                    
                    if pastMeetings.isNotEmpty || futureMeetings.isNotEmpty {
                        ForEach(futureMeetings, id: \.title) { futureMeetingSection in
                            MeetingsListHeaderView(title: futureMeetingSection.title)
                                .listRowInsets(EdgeInsets())
                            ForEach(futureMeetingSection.items) { futureMeeting in
                                FutureMeetingRoomView(viewModel: futureMeeting)
                                    .listRowInsets(EdgeInsets())
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onAppear {
                                                    viewModel.updateTipOffsetY(for: futureMeeting, meetingframeInGlobal: geo.frame(in: .global))
                                                }
                                                .onDisappear {
                                                    viewModel.updateTipOffsetY(for: futureMeeting, meetingframeInGlobal: nil)
                                                }
                                                .onChange(of: geo.frame(in: .global)) { _ in
                                                    viewModel.updateTipOffsetY(for: futureMeeting, meetingframeInGlobal: geo.frame(in: .global))
                                                }
                                                
                                        }
                                    )
                            }
                        }
                        
                        MeetingsListHeaderView(title: Strings.Localizable.Chat.Listing.SectionHeader.PastMeetings.title)
                            .listRowInsets(EdgeInsets())
                        ForEach(pastMeetings) { pastMeeting in
                            ChatRoomView(viewModel: pastMeeting)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
                .listStyle(.plain)
                .overlay(
                    VStack {
                        if viewModel.isChatRoomEmpty {
                            ChatRoomsEmptyView(emptyViewState: viewModel.isSearchActive ? viewModel.searchEmptyViewState() : viewModel.emptyChatRoomsViewState())
                        }
                    }
                    , alignment: .center
                )
                .scrollStatusMonitor($viewModel.isMeetingListScrolling)
            } else {
                LoadingSpinner()
            }
        }
    }
}
