import ChatRepo
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation

@MainActor
protocol ShareLinkDialogRouting {
    func showShareLinkDialog(_ data: ShareLinkRequestData)
}

typealias PresentationHandler = (SimpleDialogConfig, UIViewController) -> UIViewController
typealias ShareActivityFactory = (ChatLinkPresentationItemSource, URL, UIView) -> UIViewController
/// Handles presentation and actions of a dialog view.
/// Used when a scheduled meeting or an occurrence of it, is created or updated with meeting link
/// setting enabled
/// It shows a modal with 2 actions : send link to MEGA chat(s) or share link via native share sheet
/// *When sharing via share sheet, on the iPad, presentation controller is attached to the button that trigger that action*
final class ShareLinkDialogRouter: ShareLinkDialogRouting {
    
    static func defaultPresentationHandler() -> PresentationHandler {
        { config, presenter in
            return BottomSheetRouter(
                presenter: presenter,
                content: SimpleDialogView(dialogConfig: config)
            ).build()
        }
    }
    
    static func defaultShareActivityFactory() -> ShareActivityFactory {
        { metadataItemSource, link, view in
            let shareActivity = UIActivityViewController(
                activityItems: [metadataItemSource],
                applicationActivities: [SendToChatActivity(text: link.absoluteString)]
            )
            shareActivity.popoverPresentationController?.sourceView = view
            return shareActivity
        }
    }
    
    private weak var presenter: UIViewController?
    private let presentationHandler: PresentationHandler
    private let tracker: any AnalyticsTracking
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatLinkUseCase: any ChatLinkUseCaseProtocol
    private var sendToChatPresenter: (any SendToChatPresenting)?
    // presented modal dialog instance is retained here,
    // to be able to present activity on it
    // as given VC cannot present two children at once
    private var dialog: UIViewController?
    
    private let shareActivityFactory: ShareActivityFactory
    private let sendToChatPresentingFactory: any SendToChatPresentingFactoryProtocol
    init(
        presenter: UIViewController,
        presentationHandler: PresentationHandler? = nil,
        chatRoomUseCase: some ChatRoomUseCaseProtocol = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
        chatLinkUseCase: some ChatLinkUseCaseProtocol = ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
        tracker: some AnalyticsTracking = DIContainer.tracker,
        sendToChatPresentingFactory: (any SendToChatPresentingFactoryProtocol)? = nil,
        shareActivityFactory: ShareActivityFactory? = nil
    ) {
        self.presenter = presenter
        self.presentationHandler = presentationHandler ?? Self.defaultPresentationHandler()
        self.tracker = tracker
        self.chatRoomUseCase = chatRoomUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.shareActivityFactory = shareActivityFactory ?? Self.defaultShareActivityFactory()
        self.sendToChatPresentingFactory = sendToChatPresentingFactory ?? SendToChatPresentingFactory()
    }
    
    func showShareLinkDialog(_ data: ShareLinkRequestData) {
        guard let presenter = presenter else { return }
        let dialogConfig = SimpleDialogConfigFactory.shareLinkDialog(
            sendAction: { @MainActor [weak self] _ in
                presenter.dismiss(animated: true)
                guard let self else { return }
                tracker.trackAnalyticsEvent(with: SendMeetingLinkToChatScheduledMeetingEvent())
                await sendLink(chatId: data.chatId)
            },
            shareAction: { @MainActor [weak self] view in
                // can't dismiss so that we have source view on the iPad
                guard let self else { return }
                tracker.trackAnalyticsEvent(with: ShareMeetingLinkScheduledMeetingEvent())
                await shareLink(data: data, view: view)
            }
        )
        dialog = presentationHandler(dialogConfig, presenter)
        if let dialog {
            tracker.trackAnalyticsEvent(with: ShareLinkDialogEvent())
            presenter.present(dialog, animated: true)
        }
    }
    
    private func createLink(chatId: ChatIdEntity) async -> URL? {
        
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatId) else {
            return nil
        }
        
        do {
            let link = try await chatLinkUseCase.queryChatLink(for: chatRoom)
            return URL(string: link)
        } catch {
            MEGALogWarning("link not present, will continue to create it: \(error)")
        }
        
        do {
            let link = try await chatLinkUseCase.createChatLink(for: chatRoom)
            return URL(string: link)
        } catch {
            MEGALogError("cannot create link: \(error)")
            return nil
        }
    }
    
    private func shareLink(data: ShareLinkRequestData, view: UIView) async {
        
        guard let link = await createLink(chatId: data.chatId) else {
            return
        }
        
        let metadataItemSource = ChatLinkPresentationItemSourceFactory.makeItemSource(
            title: data.title,
            subtitle: data.subtitle,
            username: data.username,
            url: link
        )
        
        let shareActivity = shareActivityFactory(metadataItemSource, link, view)
        dialog?.present(shareActivity, animated: true)
    }
    
    private func sendLink(chatId: ChatIdEntity) async {
        guard
            let link = await createLink(chatId: chatId),
            let presenter
        else { return }
        
        sendToChatPresenter = sendToChatPresentingFactory.make(link: link.absoluteString)
        sendToChatPresenter?.showSendToChat(presenter: presenter)
    }
}
