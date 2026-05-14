import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

@MainActor
final class TransfersSettingsViewModel: ObservableObject {

    enum ConnectionType: Identifiable {
        case download
        case upload

        var id: Self { self }

        var title: String {
            switch self {
            case .download: Strings.Localizable.Settings.Transfers.Connections.Download.title
            case .upload: Strings.Localizable.Settings.Transfers.Connections.Upload.title
            }
        }

        var defaultValue: Int {
            switch self {
            case .download: 4
            case .upload: 3
            }
        }
    }

    @Published var downloadConnections: Int
    @Published var uploadConnections: Int
    @Published var presentedSheet: ConnectionType?
    @Published var snackBar: SnackBar?

    let options = Array(1...8)

    private let useCase: any TransfersSettingsUseCaseProtocol
    private let tracker: any AnalyticsTracking

    init(
        useCase: some TransfersSettingsUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.useCase = useCase
        self.tracker = tracker
        self.downloadConnections = ConnectionType.download.defaultValue
        self.uploadConnections = ConnectionType.upload.defaultValue
    }

    func trackScreenView() {
        tracker.trackAnalyticsEvent(with: TransfersSettingsScreenEvent())
    }

    func loadConnections() async {
        do {
            async let downloads = useCase.maxDownloadConnections()
            async let uploads = useCase.maxUploadConnections()
            let (dl, ul) = try await (downloads, uploads)
            downloadConnections = dl
            uploadConnections = ul
        } catch {
            MEGALogError("[TransfersSettings] Error loading connections from SDK: \(error)")
        }
    }

    func select(_ value: Int, for type: ConnectionType) async {
        let previousValue = self.value(for: type)
        set(value, for: type)
        trackConnectionChanged(type: type, previousValue: previousValue, newValue: value)
        do {
            switch type {
            case .download:
                try await useCase.setMaxDownloadConnections(value)
            case .upload:
                try await useCase.setMaxUploadConnections(value)
            }
        } catch {
            set(previousValue, for: type)
            snackBar = SnackBar(message: Strings.Localizable.somethingWentWrong)
            MEGALogError("[TransfersSettings] Error setting \(type.title): \(error)")
        }
    }

    func subtitle(for type: ConnectionType) -> String {
        let value = value(for: type)
        if let suffix = optionSuffix(for: value, type: type) {
            return "\(value) (\(suffix))"
        }
        return "\(value)"
    }

    func value(for type: ConnectionType) -> Int {
        switch type {
        case .download: downloadConnections
        case .upload: uploadConnections
        }
    }

    func optionSuffix(for value: Int, type: ConnectionType) -> String? {
        if value == type.defaultValue {
            return Strings.Localizable.Settings.Transfers.Connections.Option.default
        }
        switch value {
        case 1: return Strings.Localizable.Settings.Transfers.Connections.Option.bestForSlowNetworks
        case 8: return Strings.Localizable.Settings.Transfers.Connections.Option.higherUsage
        default: return nil
        }
    }

    func onTap(_ type: ConnectionType) {
        presentedSheet = type
        trackDialogDisplayed(type: type)
    }

    private func set(_ value: Int, for type: ConnectionType) {
        switch type {
        case .download: downloadConnections = value
        case .upload: uploadConnections = value
        }
    }

    private func trackDialogDisplayed(type: ConnectionType) {
        switch type {
        case .download:
            tracker.trackAnalyticsEvent(with: DownloadConnectionsDialogEvent())
        case .upload:
            tracker.trackAnalyticsEvent(with: UploadConnectionsDialogEvent())
        }
    }

    private func trackConnectionChanged(type: ConnectionType, previousValue: Int, newValue: Int) {
        let previous = Int32(previousValue)
        let new = Int32(newValue)
        switch type {
        case .download:
            tracker.trackAnalyticsEvent(with: DownloadConnectionsChangedEvent(previousValue: previous, newValue: new))
        case .upload:
            tracker.trackAnalyticsEvent(with: UploadConnectionsChangedEvent(previousValue: previous, newValue: new))
        }
    }
}
