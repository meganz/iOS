import SwiftUI
import Foundation
import MEGAFoundation
import MEGADomain
import MEGAPresentation

final class RecentsQuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadWidget
    }

    // MARK: - Private properties
    private let credentialUseCase: CredentialUseCaseProtocol
    private let copyDataBasesUseCase: CopyDataBasesUseCaseProtocol
    private let recentItemsUseCase: RecentItemsUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?

    init(credentialUseCase: CredentialUseCaseProtocol, copyDataBasesUseCase: CopyDataBasesUseCaseProtocol, recentItemsUseCase: RecentItemsUseCaseProtocol) {
        self.credentialUseCase = credentialUseCase
        self.copyDataBasesUseCase = copyDataBasesUseCase
        self.recentItemsUseCase = recentItemsUseCase
    }
    
    var status: WidgetStatus = .notConnected { didSet { invokeCommand?(.reloadWidget) } }
    
    // MARK: - Dispatch action
    func dispatch(_ action: QuickAccessWidgetAction) {
        switch action {
        case .onWidgetReady:
            status = .notConnected
            connectWidgetExtension()
        }
    }
    
    func fetchRecentItems() -> EntryValue {
        if credentialUseCase.hasSession() {
            let items = recentItemsUseCase.fetchRecentItems().map {
                QuickAccessItemModel(thumbnail: imageForPatExtension(URL(fileURLWithPath:$0.name).pathExtension), name: $0.name, url: URL(string: SectionDetail.recents.link)?.appendingPathComponent($0.base64Handle), image: $0.isUpdate ? Image(Asset.Images.Generic.versioned.name): Image(Asset.Images.Recents.recentUpload.name), description: recentStringTimestamp($0.timestamp))
            }
            return (items, .connected)
        } else {
            return ([], .noSession)
        }
    }
    
    //MARK: -Private
    func recentStringTimestamp(_ timestamp: Date) -> String {
        if timestamp.isToday(on: Calendar.current) {
            return DateFormatter.timeShort().localisedString(from: timestamp)
        } else {
            return DateFormatter.dateMedium().localisedString(from: timestamp)
        }
    }
    
    private func imageForPatExtension(_ pathExtension: String) -> Image {
        if pathExtension != "" {
            return Image(FileTypes().allTypes[pathExtension] ?? Asset.Images.Filetypes.generic.name)
        } else {
            return Image(Asset.Images.Filetypes.folder.name)
        }
    }
    
    private func updateStatus(_ newStatus: WidgetStatus) {
        if status != newStatus {
            status = newStatus
        }
    }
    
    private func connectWidgetExtension() {
        if status == .connecting {
            return
        }
        self.updateStatus(.connecting)

        copyDataBasesUseCase.copyFromMainApp { (result) in
            switch result {
            case .success(_):
                self.updateStatus(.connected)
            case .failure(_):
                self.updateStatus(.error)
            }
        }
    }
}
