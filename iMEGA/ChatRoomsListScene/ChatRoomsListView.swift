import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomsListView: View {
    @ObservedObject var viewModel: ChatRoomsListViewModel

    var body: some View {
        VStack(spacing: 0) {
            ChatTabsSelectorView(
                chatViewMode: viewModel.chatViewMode,
                shouldDisplayUnreadBadgeForChats: viewModel.shouldDisplayUnreadBadgeForChats,
                shouldDisplayUnreadBadgeForMeetings: viewModel.shouldDisplayUnreadBadgeForMeetings
            ) { mode in
                viewModel.selectChatMode(mode)
            }
            
            if let activeCallViewModel = viewModel.activeCallViewModel {
                ChatRoomActiveCallView(viewModel: activeCallViewModel)
            }
            
            if let offlineEmptyState = viewModel.noNetworkEmptyViewState() {
                ChatRoomsEmptyView(emptyViewState: offlineEmptyState)
            } else {
                content()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                MyAvatarIconView(
                    viewModel: .init(
                        avatarObserver: viewModel.myAvatarViewModel,
                        onAvatarTapped: { viewModel.openUserProfile() }
                    )
                )
            }
            
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.title)
                        .font(.headline)
                        .lineLimit(1)
                    if let subtitle = viewModel.chatStatus?.localizedIdentifier {
                        Text(subtitle)
                            .font(.caption)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                switch viewModel.chatViewMode {
                case .chats:
                    Button {
                        viewModel.addChatButtonTapped()
                    } label: {
                        Image(uiImage: UIImage.navigationbarAdd)
                    }
                    .disabled(!viewModel.isConnectedToNetwork)
                case .meetings:
                    addMenuButton {
                        Image(uiImage: UIImage.navigationbarAdd)
                    }
                    .disabled(!viewModel.isConnectedToNetwork)
                }
                
                contextMenuButton {
                    Image(uiImage: UIImage.moreNavigationBar)
                }
            }
        }
        .background()
        .task {
            await viewModel.askForNotificationsPermissionsIfNeeded()
        }
        .onAppear {
            viewModel.loadChatRoomsIfNeeded()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        .onLoad {
            viewModel.trackScreenAppearance()
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
    
    func addMenuButton<Label: View>(@ViewBuilder label: @escaping () -> Label) -> ContextMenuWithButtonView<Label>? {
        return viewModel.contextMenuManager.menu(with: viewModel.addMeetingsMenuConfiguration, label: label)
    }
    
    func contextMenuButton<Label: View>(@ViewBuilder label: @escaping () -> Label) -> ContextMenuWithButtonView<Label>? {
        guard let config = viewModel.contextMenuConfiguration else { return nil }
        return viewModel.contextMenuManager.menu(with: config, label: label)
    }

    @ViewBuilder
    func emptyView(state: ChatRoomsEmptyViewState) -> some View {
        if viewModel.isSearching {
            ChatRoomsEmptyView(
                emptyViewState: state
            )
        } else {
            NewChatRoomsEmptyView(
                state: state,
                topPadding: 100
            )
        }
    }
    
    @ViewBuilder
    private func searchBarView() -> some View {
        SearchBarView(
            text: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            placeholder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel
        )
        .listRowSeparator(.hidden)
        .listRowBackground(TokenColors.Background.page.swiftUI)
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
                        if !viewModel.isSearchActive && viewModel.existMoreChatsThanNoteToSelf {
                            ChatRoomsTopRowView(state: viewModel.contactsOnMegaViewState)
                                .onTapGesture(perform: viewModel.contactsOnMegaViewState.action)
                                .listRowInsets(EdgeInsets())
                                .padding(10)
                                .background()
                        }
                        
                        ForEach(chatRooms) { chatRoom in
                            ChatRoomView(viewModel: chatRoom)
                                .listRowSeparator(viewModel.existMoreChatsThanNoteToSelf ? .visible : .hidden)
                                .listRowInsets(EdgeInsets())
                                .background()
                        }
                    }
                }
                .listStyle(.plain)
                .overlay(
                    VStack {
                        if let emptyViewState = viewModel.emptyViewState() {
                            emptyView(
                                state: emptyViewState
                            )
                        }
                    }
                    , alignment: .center
                )
                .background()
                .scrollBounceBasedOnSize
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
                                .listRowBackground(TokenColors.Background.page.swiftUI)
                            ForEach(futureMeetingSection.items) { futureMeeting in
                                FutureMeetingRoomView(viewModel: futureMeeting)
                                    .listRowInsets(EdgeInsets())
                                    .background()
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
                            .listRowBackground(TokenColors.Background.page.swiftUI)
                        ForEach(pastMeetings) { pastMeeting in
                            ChatRoomView(viewModel: pastMeeting)
                                .listRowInsets(EdgeInsets())
                                .background()
                        }
                    }
                }
                .listStyle(.plain)
                .overlay(
                    VStack {
                        if let emptyViewState = viewModel.emptyViewState() {
                            emptyView(state: emptyViewState)
                        }
                    },
                    alignment: .center
                )
                .background()
                .scrollStatusMonitor($viewModel.isMeetingListScrolling)
            } else {
                LoadingSpinner()
            }
        }
    }
}
