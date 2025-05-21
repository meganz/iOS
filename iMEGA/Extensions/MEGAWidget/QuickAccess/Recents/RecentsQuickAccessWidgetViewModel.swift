import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAFoundation
import MEGASwift
import SwiftUI

final class RecentsQuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadWidget
    }

    // MARK: - Private properties
    private let credentialUseCase: any CredentialUseCaseProtocol
    private let copyDataBasesUseCase: any CopyDataBasesUseCaseProtocol
    private let recentItemsUseCase: any RecentItemsUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?

    init(credentialUseCase: any CredentialUseCaseProtocol,
         copyDataBasesUseCase: any CopyDataBasesUseCaseProtocol,
         recentItemsUseCase: any RecentItemsUseCaseProtocol) {
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
            let items = recentItemsUseCase
                .fetchRecentItems()
                .map(quickAccessItemModel(from:))
            
            return (items, .connected)
        } else {
            return ([], .noSession)
        }
    }
    
    private func quickAccessItemModel(
        from item: RecentItemEntity
    ) -> QuickAccessItemModel {
        QuickAccessItemModel(
            thumbnail: imageForPatExtension(item.name.pathExtension),
            name: item.name,
            url: URL(string: SectionDetail.recents.link)?
                .appendingPathComponent(item.base64Handle),
            image: item.isUpdate ? MEGAAssets.Image.versioned : MEGAAssets.Image.recentUpload,
            description: recentStringTimestamp(item.timestamp)
        )
    }
    
    // MARK: - Private
    func recentStringTimestamp(_ timestamp: Date) -> String {
        if timestamp.isToday(on: Calendar.current) {
            return DateFormatter.timeShort().localisedString(from: timestamp)
        } else {
            return DateFormatter.dateMedium().localisedString(from: timestamp)
        }
    }
    
    private func imageForPatExtension(_ pathExtension: String) -> Image {
        if pathExtension != "" {
            return MEGAAssets.Image.image(forFileExtension: pathExtension)
        } else {
            return MEGAAssets.Image.filetypeFolder
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
            case .success:
                self.updateStatus(.connected)
            case .failure:
                self.updateStatus(.error)
            }
        }
    }
}
