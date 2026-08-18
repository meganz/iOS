import MEGAAppPresentation
import MEGAAssets
import MEGAConnectivity
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import Transfer

struct ChatRoomsListView: View {
    @ObservedObject var viewModel: ChatRoomsListViewModel

    var body: some View {
        // New offline mode: shared banner below the navigation bar; the chats already on the
        // device stay listed and browsable while offline (IOS-12414). With the flag off only the
        // banner is suppressed: applying the modifier conditionally instead would change the
        // content's structural identity, resetting the list and the toolbar beneath it.
        tabContent
        .modifier(NoInternetViewModifier(
            isHidden: !viewModel.isNewOfflineModeEnabled,
            viewModel: MEGAConnectivity.DependencyInjection.networkPathNoInternetViewModel
        ))
        .toolbar {
            TransferIndicatorBarItemConfigurator.toolbarFactory.toolbarContent(trailingItemCount: 2)

            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.title)
                        .font(.headline)
                        .lineLimit(1)
                    if let subtitle = viewModel.displayedChatStatus?.localizedIdentifier {
                        Text(subtitle)
                            .font(.caption)
                    }
                }
            }

            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    switch viewModel.chatViewMode {
                    case .chats:
                        Button {
                            viewModel.addChatButtonTapped()
                        } label: {
                            addImage
                        }
                        .disabled(!viewModel.isConnectedToNetwork)
                    case .meetings:
                        addMenuButton {
                            addImage
                        }
                        .disabled(!viewModel.isConnectedToNetwork)
                    }
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItem(placement: .topBarTrailing) {
                    contextMenuButton {
                        moreImage
                    }
                    .disabled(!viewModel.actionsRequiringConnectionEnabled)
                }
            } else {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    switch viewModel.chatViewMode {
                    case .chats:
                        Button {
                            viewModel.addChatButtonTapped()
                        } label: {
                            addImage
                        }
                        .disabled(!viewModel.isConnectedToNetwork)
                    case .meetings:
                        addMenuButton {
                            addImage
                        }
                        .disabled(!viewModel.isConnectedToNetwork)
                    }

                    contextMenuButton {
                        moreImage
                    }
                    .disabled(!viewModel.actionsRequiringConnectionEnabled)
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
                    .onChange(of: geo.frame(in: .global)) { _, _ in
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
    
    private var tabContent: some View {
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
        .environment(
            \.chatListActionsRequiringConnectionEnabled,
            viewModel.actionsRequiringConnectionEnabled
        )
    }

    private var addImage: some View {
        navigationBarIcon(MEGAAssets.UIImage.navigationbarAdd)
    }

    private var moreImage: some View {
        navigationBarIcon(MEGAAssets.UIImage.moreNavigationBar)
    }

    /// The assets carry their own colours, so `.disabled(_:)` alone leaves them looking tappable.
    /// They are greyed out explicitly to match the disabled state of the button around them.
    /// Template rendering is what lets the tint through, so it is only turned on with the new
    /// offline mode, leaving the icons drawn from the asset as before behind the flag.
    private func navigationBarIcon(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .renderingMode(viewModel.isNewOfflineModeEnabled ? .template : .original)
            .foregroundStyle(
                viewModel.actionsRequiringConnectionEnabled
                ? TokenColors.Icon.primary.swiftUI
                : TokenColors.Icon.disabled.swiftUI
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
    private func archivedChatsRow() -> some View {
        if viewModel.shouldShowArchivedChatsRow {
            let state = viewModel.archiveChatsViewState
            ChatRoomsTopRowView(state: state)
                .onTapGesture(perform: state.action)
                .listRowInsets(EdgeInsets())
                .padding(10)
                .background()
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

                    archivedChatsRow()

                    if chatRooms.isNotEmpty {
                        if viewModel.shouldShowContactsOnMegaRow {
                            ChatRoomsTopRowView(state: viewModel.contactsOnMegaViewState)
                                .onTapGesture(perform: viewModel.contactsOnMegaViewState.action)
                                .disabled(!viewModel.isContactsOnMegaRowEnabled)
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
                .scrollBounceBehavior(.basedOnSize)
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

                    archivedChatsRow()

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
                                                .onChange(of: geo.frame(in: .global)) { _, _ in
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
