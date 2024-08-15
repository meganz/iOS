@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import MEGASwift
import XCTest

extension WaitingRoomConfig {
    static let admittanceEnabled = WaitingRoomConfig(
        allowIndividualWaitlistAdmittance: true
    )
}

class MeetingFloatingPanelViewModelTests: XCTestCase {
    
    func makeDevicePermissionHandler(authorized: Bool = false) -> MockDevicePermissionHandler {
        .init(
            photoAuthorization: .authorized,
            audioAuthorized: authorized,
            videoAuthorized: authorized
        )
    }
    
    // most of the test use the same values of parameters
    // using single place to create this value makes it easier to reuse and to add new parameter value
    let defaultSections: [FloatingPanelTableViewSection] = [.hostControls, .invite, .participants]
    let headerConfigFactory = MockMeetingFloatingPanelHeaderConfigFactory()
    func listView(
        hostControlsRows: [HostControlsSectionRow],
        inviteSectionRow: [InviteSectionRow] = [],
        tabs: [ParticipantsListTab] = [.inCall, .notInCall],
        selectedTab: ParticipantsListTab,
        participants: [CallParticipantEntity] = [],
        existsWaitingRoom: Bool = false,
        currentUserHandle: HandleEntity? = .invalidHandle,
        isMyselfModerator: Bool = false,
        infoHeaderData: MeetingInfoHeaderData? = nil
    ) -> ParticipantsListView {
        .init(
            // in this file we are testing MeetingFloatingPanelViewModel and not MockMeetingFloatingPanelHeaderConfigFactory
            // ** there are separate unit tests for the MockMeetingFloatingPanelHeaderConfigFactory ***
            // so we are supplying a mock version that produces constant values that do not interfere with the comparison tests
            headerConfig: headerConfigFactory.headerConfig(
                tab: selectedTab,
                freeTierInCallParticipantLimitReached: false,
                totalInCallAndWaitingRoomAboveFreeTierLimit: false,
                participantsCount: participants.count,
                isMyselfAModerator: isMyselfModerator,
                hasDismissedBanner: false,
                shouldHideCallAllIcon: false,
                shouldDisableMuteAllButton: false,
                presentUpgradeFlow: {},
                dismissFreeUserLimitBanner: {},
                actionButtonTappedHandler: {}
            ),
            sections: defaultSections,
            hostControlsRows: hostControlsRows,
            inviteSectionRow: inviteSectionRow,
            tabs: tabs,
            selectedTab: selectedTab,
            participants: participants,
            // for backwards test compatibility we do variations only of the waiting room enabled/disable case
            waitingRoomConfig: existsWaitingRoom ? .admittanceEnabled : nil,
            currentUserHandle: currentUserHandle,
            isMyselfModerator: isMyselfModerator
        )
    }
    
    let audioSessionUseCase = MockAudioSessionUseCase()
    let callUseCase = MockCallUseCase(call: CallEntity())
    
    // will migrate eventually all places we create SUT to use this method as any change in parameters of view model
    // forces us to adjust parameters in 50 places right now, clearly not sustainable
    func makeSUT(
        chatType: ChatRoomEntity.ChatType = .meeting
    ) -> MeetingFloatingPanelViewModel {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: chatType)
        
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let viewModel = MeetingFloatingPanelViewModel.make(
            router: MockMeetingFloatingPanelRouter(),
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            headerConfigFactory: headerConfigFactory
        )
        return viewModel
    }
    
    @MainActor func testAction_onViewReady_isMyselfModerator_isGroupMeeting() {
        let viewModel = makeSUT()
        test(
            viewModel: viewModel,
            action: .onViewReady,
            expectedCommands: [
                .configView(
                    canInviteParticipants: true,
                    isOneToOneCall: false,
                    isMeeting: true,
                    allowNonHostToAddParticipantsEnabled: false,
                    isMyselfAModerator: true
                ),
                .reloadParticipantsList(participants: []),
                .microphoneMuted(muted: true)
            ]
        )
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_onViewAppear_selectWaitingRoomList() {
        let viewModel = MeetingFloatingPanelViewModel.make(selectWaitingRoomList: true,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .onViewAppear,
             expectedCommands: [
                .transitionToLongForm
             ])
    }
    
    @MainActor func testAction_selectParticipantsInCall_isOneToOneCall_reloadViewDataForOneToOne() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(
            viewModel: viewModel,
            action: .selectParticipantsList(selectedTab: .inCall),
            expectedCommands: [
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [],
                        inviteSectionRow: [], // user can't invite into 1-on-1 calls
                        selectedTab: .inCall,
                        participants: [],
                        isMyselfModerator: true
                    )
                )
            ]
        )
    }
    
    @MainActor func testAction_selectParticipantsInCall_isGroupCallAndModerator_reloadViewDataForGroupCallModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group, isOpenInviteEnabled: false)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: listView(hostControlsRows: [.listSelector, .allowNonHostToInvite], inviteSectionRow: [.invite], selectedTab: .inCall, participants: [], isMyselfModerator: true))
             ])
    }
    
    @MainActor func testAction_selectParticipantsInCall_isGroupCallAndNoModerator_reloadViewDataForGroupCallNoModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: false)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: listView(hostControlsRows: [.listSelector], selectedTab: .inCall))
             ])
    }
    
    @MainActor func testAction_selectParticipantsInCall_isGroupCallAndOpenInvite_reloadViewDataForGroupCallEnabledOpenInvite() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: true)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: listView(hostControlsRows: [.listSelector], inviteSectionRow: [.invite], selectedTab: .inCall))
             ])
    }
    
    @MainActor func testAction_selectParticipantsNotInCall_isGroupCallAndModerator_reloadViewDataForGroupCallModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group, isOpenInviteEnabled: false)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(
            viewModel: viewModel,
            action: .selectParticipantsList(selectedTab: .notInCall),
            expectedCommands: [
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [.listSelector],
                        selectedTab: .notInCall,
                        isMyselfModerator: true
                    )
                )
            ]
        )
    }
    
    @MainActor func testAction_selectParticipantsNotInCall_isGroupCallAndModerator_reloadViewDataForGroupCallNoModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: false)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .notInCall),
             expectedCommands: [
                .reloadViewData(participantsListView: listView(hostControlsRows: [.listSelector], selectedTab: .notInCall))
             ])
    }
    
    @MainActor func testAction_selectParticipantsNotInCall_isGroupCallAndOpenInvite_reloadViewDataForGroupCallEnabledOpenInvite() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: true)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .notInCall),
             expectedCommands: [
                .reloadViewData(participantsListView: listView(hostControlsRows: [.listSelector], selectedTab: .notInCall))
             ])
    }
    
    @MainActor func testAction_selectParticipantsInWaitingRoom_isMeetingAndModerator_reloadViewDataForMeetingModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting, isWaitingRoomEnabled: true)
        
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoom: chatRoom,
                                                           headerConfigFactory: headerConfigFactory)
        test(
            viewModel: viewModel,
            action: .selectParticipantsList(selectedTab: .waitingRoom),
            expectedCommands: [
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [.listSelector],
                        tabs: [.inCall, .notInCall, .waitingRoom],
                        selectedTab: .waitingRoom,
                        participants: [],
                        existsWaitingRoom: true,
                        isMyselfModerator: true
                    )
                )
            ]
        )
    }
    
    @MainActor func testAction_selectParticipantsInWaitingRoom_isMeetingAndNonModerator_reloadViewDataForMeetingNoModerator() {
        let chatRoom = ChatRoomEntity(
            ownPrivilege: .standard,
            chatType: .meeting,
            isWaitingRoomEnabled: true
        )
        
        let viewModel = MeetingFloatingPanelViewModel.make(
            chatRoom: chatRoom,
            headerConfigFactory: headerConfigFactory
        )
        test(
            viewModel: viewModel,
            action: .selectParticipantsList(selectedTab: .waitingRoom),
            expectedCommands: [
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [.listSelector],
                        selectedTab: .waitingRoom,
                        existsWaitingRoom: false
                    )
                )
            ]
        )
    }
    
    @MainActor func testAction_onViewReady_isMyselfModerator_isOneToOneMeeting() {
        let canInviteParticipants = false // one or one calls do not allow inviting
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(router: MockMeetingFloatingPanelRouter(),
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        test(
            viewModel: viewModel,
            action: .onViewReady,
            expectedCommands: [
                .configView(
                    canInviteParticipants: canInviteParticipants,
                    isOneToOneCall: true,
                    isMeeting: false,
                    allowNonHostToAddParticipantsEnabled: false,
                    isMyselfAModerator: true
                ),
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [],
                        selectedTab: .inCall,
                        participants: [CallParticipantEntity.myself(handle: 100, userName: "", chatRoom: chatRoom, raisedHand: false)],
                        existsWaitingRoom: false,
                        currentUserHandle: 100,
                        isMyselfModerator: true
                    )
                )
            ]
        )
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_onViewReady_isMyselfParticipant_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(router: MockMeetingFloatingPanelRouter(),
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: false),
                .reloadParticipantsList(participants: []),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_onViewReady_isMyselfParticipant_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .oneToOne)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(router: MockMeetingFloatingPanelRouter(),
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: false),
                .reloadViewData(participantsListView: listView(hostControlsRows: [], selectedTab: .inCall, participants: [CallParticipantEntity.myself(handle: 100, userName: "", chatRoom: chatRoom, raisedHand: false)], existsWaitingRoom: false, currentUserHandle: 100))
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    @MainActor func testAction_onViewReady_isMyselfParticipant_allowNonHostToAddParticipantsEnabled() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting, isOpenInviteEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(router: MockMeetingFloatingPanelRouter(),
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, allowNonHostToAddParticipantsEnabled: true, isMyselfAModerator: false),
                .reloadParticipantsList(participants: []),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    

    @MainActor func testAction_shareLink_Success() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success("https://mega.link"))
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel.make(router: router,
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        await test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssert(containerRouter.shareLink_calledTimes == 1)
    }
    
    @MainActor func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerRouter = MockMeetingContainerRouter()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel.make(router: router,
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.shareLink_calledTimes == 0)
    }
    
    @MainActor func testAction_inviteParticipants() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let viewModel = MeetingFloatingPanelViewModel.make(router: router, accountUseCase: accountUseCase, chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()),
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticipants_calledTimes == 1)
    }
    
    @MainActor func testAction_inviteParticipants_showAllContactsAlreadyAddedAlert() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomUseCase = MockChatRoomUseCase(myPeerHandles: [101])
        let viewModel = MeetingFloatingPanelViewModel.make(router: router, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.showAllContactsAlreadyAddedAlert_CalledTimes == 1)
    }
    
    @MainActor func testAction_inviteParticipants_showNoAvailableContactsAlert() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .blocked)
        ])
        let viewModel = MeetingFloatingPanelViewModel.make(router: router, accountUseCase: accountUseCase,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.showNoAvailableContactsAlert_CalledTimes == 1)
    }
    
    @MainActor func testAction_inviteParticipants_singleContactBlocked() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .blocked)
        ])
        let viewModel = MeetingFloatingPanelViewModel.make(router: router, accountUseCase: accountUseCase,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticipants_calledTimes == 0)
    }
    
    @MainActor func testAction_inviteParticipants_singleContactVisible() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let viewModel = MeetingFloatingPanelViewModel.make(router: router, accountUseCase: accountUseCase, chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()),
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticipants_calledTimes == 1)
    }
    
    @MainActor
    func testAction_inviteParticipants_singleAddedContactAndABlockedContact() {
        let router = MockMeetingFloatingPanelRouter()
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible),
            UserEntity(email: "user@email.com", handle: 102, visibility: .blocked)
        ])
        let chatRoomUseCase = MockChatRoomUseCase(myPeerHandles: [101])
        let viewModel = MeetingFloatingPanelViewModel.make(router: router, accountUseCase: mockAccountUseCase, chatRoomUseCase: chatRoomUseCase,
                                                           headerConfigFactory: headerConfigFactory)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.showAllContactsAlreadyAddedAlert_CalledTimes == 1)
    }
    
    func testAction_inviteParticipants_reAddParticipantScenario() {
        let router = MockMeetingFloatingPanelRouter()
        router.invitedParticipantHandles = [101]
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let viewModel = MeetingFloatingPanelViewModel.make(
            router: router,
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            headerConfigFactory: headerConfigFactory
        )
        viewModel.dispatch(.inviteParticipants)
        XCTAssert(router.inviteParticipants_calledTimes == 1)
        viewModel.dispatch(.inviteParticipants)
        XCTAssert(router.inviteParticipants_calledTimes == 1)
    }
    
    @MainActor func testAction_contextMenuTap() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel.make(router: router,
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .onContextMenuTap(presenter: UIViewController(), sender: UIButton(), participant: particpant), expectedCommands: [])
        XCTAssert(router.showContextMenu_calledTimes == 1)
    }
    
    @MainActor func testAction_ChangeModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel.make(router: router,
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                           headerConfigFactory: headerConfigFactory)
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel,
             action: .makeModerator(participant: particpant),
             expectedCommands: [
                .reloadParticipantsList(participants: [])
             ]
        )
    }
    
    func testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteEnabled() {
        let router = MockMeetingFloatingPanelRouter()
        router.invitedParticipantHandles = [101]
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomEntity = ChatRoomEntity(chatId: 100, isOpenInviteEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let viewModel = MeetingFloatingPanelViewModel.make(
            router: router,
            chatRoom: chatRoomEntity,
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            headerConfigFactory: headerConfigFactory
        )
        
        let expectation = expectation(description: "testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteEnabled")
        viewModel.invokeCommand = { command in
            switch command {
            case .configView(_, _, _, let allowNonHostToAddParticipantsEnabled, _):
                XCTAssertTrue(allowNonHostToAddParticipantsEnabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.onViewReady)
        chatRoomUseCase.allowNonHostToAddParticipantsValueChangedSubject.send(true)
        waitForExpectations(timeout: 10)
    }
    
    func testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteDisabled() {
        let router = MockMeetingFloatingPanelRouter()
        router.invitedParticipantHandles = [101]
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomEntity = ChatRoomEntity(chatId: 100, isOpenInviteEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let viewModel = MeetingFloatingPanelViewModel.make(
            router: router,
            chatRoom: chatRoomEntity,
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            headerConfigFactory: headerConfigFactory
        )
        
        let expectation = expectation(description: "testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteDisabled")
        viewModel.invokeCommand = { command in
            switch command {
            case .configView(_, _, _, let allowNonHostToAddParticipantsEnabled, _):
                XCTAssertFalse(allowNonHostToAddParticipantsEnabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.onViewReady)
        chatRoomUseCase.allowNonHostToAddParticipantsValueChangedSubject.send(true)
        waitForExpectations(timeout: 10)
    }
    
    func testAction_updateAllowNonHostToAddParticipants_allowNonHostToAddParticipantsEnabled() {
        let chatRoomUseCase = MockChatRoomUseCase(allowNonHostToAddParticipantsEnabled: true)
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoomUseCase: chatRoomUseCase,
                                                           headerConfigFactory: headerConfigFactory)
        
        let expectation = expectation(description: "testAction_updateAllowNonHostToAddParticipants")
        viewModel.invokeCommand = { command in
            switch command {
            case .updateAllowNonHostToAddParticipants(let enabled):
                XCTAssertTrue(enabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.allowNonHostToAddParticipants(enabled: false))
        waitForExpectations(timeout: 10)
    }
    
    func testAction_updateAllowNonHostToAddParticipants_allowNonHostToAddParticipantsDisabled() {
        let chatRoomUseCase = MockChatRoomUseCase(allowNonHostToAddParticipantsEnabled: false)
        let viewModel = MeetingFloatingPanelViewModel.make(chatRoomUseCase: chatRoomUseCase,
                                                           headerConfigFactory: headerConfigFactory)
        
        let expectation = expectation(description: "testAction_updateAllowNonHostToAddParticipants")
        viewModel.invokeCommand = { command in
            switch command {
            case .updateAllowNonHostToAddParticipants(let enabled):
                XCTAssertFalse(enabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.allowNonHostToAddParticipants(enabled: true))
        waitForExpectations(timeout: 10)
    }
    
    @MainActor func testAction_seeMoreParticipantsInWaitingRoomTapped_navigateToView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .oneToOne)
        let call = CallEntity()
        let router = MockMeetingFloatingPanelRouter()
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(
            router: router,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            accountUseCase: MockAccountUseCase(),
            headerConfigFactory: headerConfigFactory
        )
        
        test(viewModel: viewModel, action: .seeMoreParticipantsInWaitingRoomTapped, expectedCommands: [])
        XCTAssert(router.showWaitingRoomParticipantsList_calledTimes == 1)
    }
    
    @MainActor func testAction_callAbsentParticipant_callIndividualParticipant() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, chatType: .oneToOne)
        let call = CallEntity()
        let router = MockMeetingFloatingPanelRouter()
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(router: router,
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(),
                                                           headerConfigFactory: headerConfigFactory)
        let participant = CallParticipantEntity(chatId: chatRoom.chatId, participantId: 1, absentParticipantState: .notInCall)
        test(viewModel: viewModel,
             action: .callAbsentParticipant(participant),
             expectedCommands: [.reloadViewData(participantsListView: listView(hostControlsRows: [], selectedTab: .inCall))]
        )
        XCTAssert(callUseCase.callAbsentParticipant_CalledTimes == 1)
        XCTAssert(participant.absentParticipantState == .calling)
    }
    
    @MainActor func testAction_AllowUsersJoinCall_usersJoin() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let router = MockMeetingFloatingPanelRouter()
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(router: router,
                                                           containerViewModel: containerViewModel,
                                                           chatRoom: chatRoom,
                                                           callUseCase: callUseCase,
                                                           accountUseCase: MockAccountUseCase(),
                                                           headerConfigFactory: headerConfigFactory)
        
        test(
            viewModel: viewModel,
            action: .selectParticipantsList(selectedTab: .waitingRoom),
            expectedCommands: [
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [.listSelector],
                        selectedTab: .waitingRoom,
                        isMyselfModerator: true
                    )
                )
            ]
        )
        
        test(viewModel: viewModel,
             action: .onHeaderActionTap,
             expectedCommands: [
                .reloadViewData(
                    participantsListView: listView(
                        hostControlsRows: [.listSelector],
                        selectedTab: .waitingRoom,
                        isMyselfModerator: true
                    )
                )
             ]
        )
        XCTAssert(callUseCase.allowUsersJoinCall_CalledTimes == 1)
    }
    
    func testAction_muteParticipant_muteSuccess() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let router = MockMeetingFloatingPanelRouter()
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingFloatingPanelViewModel.make(
            router: router,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            headerConfigFactory: headerConfigFactory
        )
        
        let participant = CallParticipantEntity(chatId: chatRoom.chatId, participantId: 1, audio: .on)
        viewModel.dispatch(.muteParticipant(participant))
        
        evaluate {
            router.showMuteSuccess_calledTimes == 1 &&
            callUseCase.muteParticipant_CalledTimes == 1
        }
    }
    
    func testAction_muteParticipant_muteError() {
        
        let harness = Harness(
            chatRoom: .moderatorMeeting,
            callUseCase: .init(call: .init(), muteParticipantCompletion: .failure(GenericErrorEntity()))
        )
        
        harness.sut.dispatch(.muteParticipant(.unmutedParticipant(chatId: harness.chatRoom.chatId)))
        
        evaluate {
            harness.router.showMuteError_calledTimes == 1 &&
            harness.callUseCase.muteParticipant_CalledTimes == 0
        }
    }
    
    func testEvent_callUpdateRaiseHandChanges_oneParticipantRaiseHand_participantsRaiseHandMustBeUpdated() async throws {
        let harness = Harness.withMonitorCallUpdates()
        harness.joinAllParticipants()
        let call = CallEntity(changeType: .callRaiseHand, raiseHandsList: [102])
        try await harness.sendCallUpdate(call)
        XCTAssertTrue(harness.raiseHandFlagsMustMatch(forCall: call))
    }
    
    func testEvent_callUpdateRaiseHandChanges_moreThanOneParticipantRaiseHand_participantsRaiseHandMustBeUpdated() async throws {
        let harness = Harness.withMonitorCallUpdates()
        harness.joinAllParticipants()
        let call = CallEntity(changeType: .callRaiseHand, raiseHandsList: [102, 103])
        try await harness.sendCallUpdate(call)
        XCTAssertTrue(harness.raiseHandFlagsMustMatch(forCall: call))
    }
    
    func testEvent_callUpdateRaiseHandChanges_participantLowerHand_participantsRaiseHandMustBeUpdated() async throws {
        let harness = Harness.withMonitorCallUpdates()
        harness.joinAllParticipants()
        let call = CallEntity(changeType: .callRaiseHand, raiseHandsList: [])
        try await harness.sendCallUpdate(call)
        XCTAssertTrue(harness.raiseHandFlagsMustMatch(forCall: call))
    }
    
    class Harness {
        let sut: MeetingFloatingPanelViewModel
        
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2)
        let thirdParticipant = CallParticipantEntity(participantId: 103, clientId: 3)
        
        lazy var callParticipants = [firstParticipant, secondParticipant, thirdParticipant]
                
        var continuation: AsyncStream<CallEntity>.Continuation?
        let chatRoom: ChatRoomEntity
        let router: MockMeetingFloatingPanelRouter
        let callUseCase: MockCallUseCase
        
        init(
            router: MockMeetingFloatingPanelRouter = .init(),
            containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
            chatRoom: ChatRoomEntity = ChatRoomEntity(),
            callUseCase: MockCallUseCase = .init(),
            callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
            accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
            chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
            chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
            selectWaitingRoomList: Bool = false,
            headerConfigFactory: some MeetingFloatingPanelHeaderConfigFactoryProtocol = MockMeetingFloatingPanelHeaderConfigFactory()
        ) {
            self.chatRoom = chatRoom
            self.router = router
            self.callUseCase = callUseCase
            
            self.sut = .init(
                router: router,
                containerViewModel: containerViewModel,
                chatRoom: chatRoom,
                callUseCase: callUseCase,
                callUpdateUseCase: callUpdateUseCase,
                accountUseCase: accountUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatUseCase: chatUseCase,
                selectWaitingRoomList: selectWaitingRoomList,
                headerConfigFactory: headerConfigFactory,
                featureFlags: MockFeatureFlagProvider(list: .init()),
                presentUpgradeFlow: { _ in }
            )
        }
        
        static func withMonitorCallUpdates() -> Harness {
            let (stream, continuation) = AsyncStream
                .makeStream(of: CallEntity.self)
            let callUpdateUseCase = MockCallUpdateUseCase(monitorCallUpdateSequenceResult: AnyAsyncThrowingSequence(stream))
            
            let harness = Harness(
                callUpdateUseCase: callUpdateUseCase
            )
            
            harness.continuation = continuation
            harness.sut.monitorOnCallUpdate()
            return harness
        }
        
        func raiseHandFlagsMustMatch(forCall call: CallEntity) -> Bool {
            let raiseHandIndex = callParticipants.partition(by: { $0.raisedHand })
            let notRaiseHandParticipants = Array(callParticipants[..<raiseHandIndex])
            let raiseHandParticipants = Array(callParticipants[raiseHandIndex...])
            
            let raiseHandIdsAreEqual = call.raiseHandsList == raiseHandParticipants.map { $0.participantId }
            
            let doesNotContainNotRaiseHandIds = !notRaiseHandParticipants.map { $0.participantId }.contains { call.raiseHandsList.contains($0)}
            
            return raiseHandIdsAreEqual && doesNotContainNotRaiseHandIds
        }
        
        func sendCallUpdate(_ call: CallEntity) async throws {
            continuation?.yield(call)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        
        func joinAllParticipants() {
            callParticipants.forEach { sut.participantJoined(participant: $0) }
        }
    }
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
}

final class MockMeetingFloatingPanelRouter: MeetingFloatingPanelRouting {
    
    var videoPermissionError_calledTimes = 0
    var audioPermissionError_calledTimes = 0
    var dismiss_calledTimes = 0
    var inviteParticipants_calledTimes = 0
    var showContextMenu_calledTimes = 0
    var showAllContactsAlreadyAddedAlert_CalledTimes = 0
    var showNoAvailableContactsAlert_CalledTimes = 0
    var invitedParticipantHandles: [HandleEntity]?
    var showConfirmDenyAction_calledTimes = 0
    var showWaitingRoomParticipantsList_calledTimes = 0
    var showMuteSuccess_calledTimes = 0
    var showMuteError_calledTimes = 0
    var showHangOrEndCallDialog_calledTimes = 0
    var triggerInviteParticipantsFromContainer_calledTimes = 0

    var viewModel: MeetingFloatingPanelViewModel? {
        return nil
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        contactPickerConfig: ContactPickerConfig,
        selectedUsersHandler: @escaping (([MEGADomain.HandleEntity]) -> Void)
    ) {
        inviteParticipants_calledTimes += 1
        if let invitedParticipantHandles = invitedParticipantHandles {
            selectedUsersHandler(invitedParticipantHandles)
        }
    }
    
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticipantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        inviteParticipants_calledTimes += 1
        if let invitedParticipantHandles = invitedParticipantHandles {
            selectedUsersHandler(invitedParticipantHandles)
        }
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showAllContactsAlreadyAddedAlert_CalledTimes += 1
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showNoAvailableContactsAlert_CalledTimes += 1
    }
    
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         participant: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel) {
        showContextMenu_calledTimes += 1
    }
    
    func showVideoPermissionError() {
        videoPermissionError_calledTimes += 1
    }
    
    func showAudioPermissionError() {
        audioPermissionError_calledTimes += 1
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {}
    
    func didSwitchToGridView() {}
    
    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        showConfirmDenyAction_calledTimes += 1
    }
    
    func showWaitingRoomParticipantsList(for call: CallEntity) {
        showWaitingRoomParticipantsList_calledTimes += 1
    }
    
    func showMuteSuccess(for participant: CallParticipantEntity?) {
        showMuteSuccess_calledTimes += 1
    }
    
    func showMuteError(for participant: CallParticipantEntity?) {
        showMuteError_calledTimes += 1
    }
    
    func showUpgradeFlow(_ accountDetails: AccountDetailsEntity) {
        
    }
    
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel) {
        showHangOrEndCallDialog_calledTimes += 1
    }
    
    func transitionToLongForm() {
        
    }
    
    var panelIsLongForm: Bool = false
    
    func triggerInviteParticipantsFromContainer() {
        triggerInviteParticipantsFromContainer_calledTimes += 1
    }
}

extension CallParticipantEntity {
    static func unmutedParticipant(chatId: HandleEntity) -> Self {
        .init(
            chatId: chatId,
            participantId: 1,
            audio: .on
        )
    }
}
