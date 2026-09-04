import FileLink
@preconcurrency import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomainMock
import MEGATest
import Testing

@Suite("FileLinkTrackingUseCase")
struct FileLinkTrackingUseCaseTests {
    @Test("Sends FileLinkScreenEvent")
    func trackScreenView() {
        let tracker = MockTracker()
        let sut = FileLinkTrackingUseCase(tracker: tracker, accountUseCase: MockAccountUseCase())

        sut.trackScreenView()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [FileLinkScreenEvent()]
        )
    }

    @Test(
        "Sends ShareLinkOpenedEvent carrying the session state",
        arguments: zip([true, false], [ShareLinkOpened.AuthStatus.loggedin, .loggedout])
    )
    func trackFileLinkOpened(isLoggedIn: Bool, authStatus: ShareLinkOpened.AuthStatus) {
        let tracker = MockTracker()
        let sut = FileLinkTrackingUseCase(
            tracker: tracker,
            accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn)
        )

        sut.trackFileLinkOpened()

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [ShareLinkOpenedEvent(linkType: .file, authStatus: authStatus)]
        )
    }

    @Test(
        "Sends the event the action and its entry point map to",
        arguments: zip(
            [
                (FileLinkMoreOption.saveToMEGA, FileLinkActionSource.anchoredButton),
                (.saveToMEGA, .moreOptionsMenu),
                (.download, .anchoredButton),
                (.download, .moreOptionsMenu),
                (.saveToPhotos, .moreOptionsMenu),
                (.copyToOffline, .moreOptionsMenu)
            ],
            [
                FileLinkSaveToMegaAnchoredButtonPressedEvent(),
                FileLinkSaveToMegaMoreOptionsButtonPressedEvent(),
                FileLinkDownloadAnchoredButtonPressedEvent(),
                FileLinkDownloadMoreOptionsButtonPressedEvent(),
                FileLinkSaveToPhotosMoreOptionsButtonPressedEvent(),
                FileLinkCopyToOfflineMoreOptionsButtonPressedEvent()
            ] as [any EventIdentifier]
        )
    )
    func trackAction(
        input: (option: FileLinkMoreOption, source: FileLinkActionSource),
        event: any EventIdentifier
    ) {
        let tracker = MockTracker()
        let sut = FileLinkTrackingUseCase(tracker: tracker, accountUseCase: MockAccountUseCase())

        sut.trackAction(input.option, from: input.source)

        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [event]
        )
    }

    /// Share link is shared straight from the sheet's own `ShareLink` row and was never tracked, and Send
    /// to chat is reported by the app layer instead. Save to Photos and Copy to Offline have no anchored
    /// button to be picked from.
    @Test(
        "Sends nothing for the combinations that carry no event",
        arguments: [
            (FileLinkMoreOption.shareLink, FileLinkActionSource.moreOptionsMenu),
            (.sendToChat, .moreOptionsMenu),
            (.saveToPhotos, .anchoredButton),
            (.copyToOffline, .anchoredButton)
        ]
    )
    func trackAction_untrackedCombination_sendsNothing(input: (option: FileLinkMoreOption, source: FileLinkActionSource)) {
        let tracker = MockTracker()
        let sut = FileLinkTrackingUseCase(tracker: tracker, accountUseCase: MockAccountUseCase())

        sut.trackAction(input.option, from: input.source)

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }
}
