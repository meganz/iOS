import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGAL10n
import MEGATest
@testable import Settings
import Testing

@Suite("TransfersSettingsViewModel")
@MainActor struct TransfersSettingsViewModelTest {

    private static func makeSUT(
        useCase: MockTransfersSettingsUseCase = MockTransfersSettingsUseCase(),
        tracker: MockTracker = MockTracker()
    ) -> (TransfersSettingsViewModel, MockTransfersSettingsUseCase, MockTracker) {
        let vm = TransfersSettingsViewModel(useCase: useCase, tracker: tracker)
        return (vm, useCase, tracker)
    }

    // MARK: - Initial State

    @Suite("Initial State")
    @MainActor struct InitialState {
        @Test("Defaults to 4 download and 3 upload connections")
        func defaultValues() {
            let (sut, _, _) = makeSUT()
            #expect(sut.downloadConnections == 4)
            #expect(sut.uploadConnections == 3)
        }

        @Test("Options range is 1 through 8")
        func optionsRange() {
            let (sut, _, _) = makeSUT()
            #expect(sut.options == Array(1...8))
        }
    }

    // MARK: - Load Connections

    @Suite("Load Connections")
    @MainActor struct LoadConnections {
        @Test("Loads values from use case")
        func loadsFromUseCase() async {
            let useCase = MockTransfersSettingsUseCase()
            useCase.maxDownloadConnectionsResult = .success(6)
            useCase.maxUploadConnectionsResult = .success(2)
            let (sut, _, _) = makeSUT(useCase: useCase)

            await sut.loadConnections()

            #expect(sut.downloadConnections == 6)
            #expect(sut.uploadConnections == 2)
        }

        @Test("Keeps defaults when use case throws")
        func keepsDefaultsOnError() async {
            let useCase = MockTransfersSettingsUseCase()
            useCase.maxDownloadConnectionsResult = .failure(GenericErrorEntity())
            useCase.maxUploadConnectionsResult = .failure(GenericErrorEntity())
            let (sut, _, _) = makeSUT(useCase: useCase)

            await sut.loadConnections()

            #expect(sut.downloadConnections == 4)
            #expect(sut.uploadConnections == 3)
        }
    }

    // MARK: - Select Connection Value

    @Suite("Select Connection Value")
    @MainActor struct SelectConnectionValue {
        @Test("Selecting download value updates property and calls use case", arguments: [1, 5, 8])
        func selectDownload(value: Int) async {
            let (sut, useCase, _) = makeSUT()

            await sut.select(value, for: .download)

            #expect(sut.downloadConnections == value)
            #expect(useCase.setMaxDownloadConnectionsCalls == [value])
        }

        @Test("Selecting upload value updates property and calls use case", arguments: [1, 5, 8])
        func selectUpload(value: Int) async {
            let (sut, useCase, _) = makeSUT()

            await sut.select(value, for: .upload)

            #expect(sut.uploadConnections == value)
            #expect(useCase.setMaxUploadConnectionsCalls == [value])
        }

        @Test("Reverts download value and shows snack bar on failure")
        func revertsDownloadOnError() async {
            let useCase = MockTransfersSettingsUseCase()
            useCase.setMaxDownloadConnectionsResult = .failure(GenericErrorEntity())
            let (sut, _, _) = makeSUT(useCase: useCase)

            await sut.select(7, for: .download)

            #expect(sut.downloadConnections == 4)
            #expect(sut.snackBar != nil)
        }

        @Test("Reverts upload value and shows snack bar on failure")
        func revertsUploadOnError() async {
            let useCase = MockTransfersSettingsUseCase()
            useCase.setMaxUploadConnectionsResult = .failure(GenericErrorEntity())
            let (sut, _, _) = makeSUT(useCase: useCase)

            await sut.select(7, for: .upload)

            #expect(sut.uploadConnections == 3)
            #expect(sut.snackBar != nil)
        }
    }

    // MARK: - Subtitle

    @Suite("Subtitle")
    @MainActor struct Subtitle {
        private static var defaultSuffix: String {
            Strings.Localizable.Settings.Transfers.Connections.Option.default
        }
        private static var slowNetworksSuffix: String {
            Strings.Localizable.Settings.Transfers.Connections.Option.bestForSlowNetworks
        }
        private static var higherUsageSuffix: String {
            Strings.Localizable.Settings.Transfers.Connections.Option.higherUsage
        }

        @Test("Shows default suffix for default download value")
        func downloadDefault() {
            let (sut, _, _) = makeSUT()
            #expect(sut.subtitle(for: .download) == "4 (\(Self.defaultSuffix))")
        }

        @Test("Shows default suffix for default upload value")
        func uploadDefault() {
            let (sut, _, _) = makeSUT()
            #expect(sut.subtitle(for: .upload) == "3 (\(Self.defaultSuffix))")
        }

        @Test("Shows slow networks suffix for value 1")
        func slowNetworks() async {
            let (sut, _, _) = makeSUT()
            await sut.select(1, for: .download)
            #expect(sut.subtitle(for: .download) == "1 (\(Self.slowNetworksSuffix))")
        }

        @Test("Shows higher usage suffix for value 8")
        func higherUsage() async {
            let (sut, _, _) = makeSUT()
            await sut.select(8, for: .download)
            #expect(sut.subtitle(for: .download) == "8 (\(Self.higherUsageSuffix))")
        }

        @Test("Shows plain number for non-default value")
        func nonDefault() async {
            let (sut, _, _) = makeSUT()
            await sut.select(6, for: .download)
            #expect(sut.subtitle(for: .download) == "6")
        }
    }

    // MARK: - Option Suffix

    @Suite("Option Suffix")
    @MainActor struct OptionSuffix {
        @Test("Returns default suffix for default download value")
        func defaultDownload() {
            let (sut, _, _) = makeSUT()
            #expect(sut.optionSuffix(for: 4, type: .download) != nil)
        }

        @Test("Returns default suffix for default upload value")
        func defaultUpload() {
            let (sut, _, _) = makeSUT()
            #expect(sut.optionSuffix(for: 3, type: .upload) != nil)
        }

        @Test("Returns slow network suffix for value 1")
        func slowNetwork() {
            let (sut, _, _) = makeSUT()
            #expect(sut.optionSuffix(for: 1, type: .download) != nil)
        }

        @Test("Returns higher usage suffix for value 8")
        func higherUsage() {
            let (sut, _, _) = makeSUT()
            #expect(sut.optionSuffix(for: 8, type: .download) != nil)
        }

        @Test("Returns nil for mid-range non-default values", arguments: [2, 5, 6, 7])
        func midRangeNil(value: Int) {
            let (sut, _, _) = makeSUT()
            #expect(sut.optionSuffix(for: value, type: .download) == nil)
        }
    }

    // MARK: - Sheet Presentation

    @Suite("Sheet Presentation")
    @MainActor struct SheetPresentation {
        @Test("onTap sets presentedSheet to download")
        func tapDownload() {
            let (sut, _, _) = makeSUT()
            sut.onTap(.download)
            #expect(sut.presentedSheet == .download)
        }

        @Test("onTap sets presentedSheet to upload")
        func tapUpload() {
            let (sut, _, _) = makeSUT()
            sut.onTap(.upload)
            #expect(sut.presentedSheet == .upload)
        }
    }

    // MARK: - Analytics

    @Suite("Analytics")
    @MainActor struct Analytics {
        @Test("Tracks screen view event")
        func screenView() {
            let (sut, _, tracker) = makeSUT()

            sut.trackScreenView()

            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [TransfersSettingsScreenEvent()]
            )
        }

        @Test("Tracks download dialog event on tap")
        func downloadDialogEvent() {
            let (sut, _, tracker) = makeSUT()

            sut.onTap(.download)

            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [DownloadConnectionsDialogEvent()]
            )
        }

        @Test("Tracks upload dialog event on tap")
        func uploadDialogEvent() {
            let (sut, _, tracker) = makeSUT()

            sut.onTap(.upload)

            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [UploadConnectionsDialogEvent()]
            )
        }

        @Test("Tracks download connection changed event on select")
        func downloadChangedEvent() async {
            let (sut, _, tracker) = makeSUT()

            await sut.select(6, for: .download)

            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [DownloadConnectionsChangedEvent(previousValue: 4, newValue: 6)]
            )
        }

        @Test("Tracks upload connection changed event on select")
        func uploadChangedEvent() async {
            let (sut, _, tracker) = makeSUT()

            await sut.select(1, for: .upload)

            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [UploadConnectionsChangedEvent(previousValue: 3, newValue: 1)]
            )
        }
    }
}
