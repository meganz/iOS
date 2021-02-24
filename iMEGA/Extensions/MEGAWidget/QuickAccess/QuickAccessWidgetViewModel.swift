
import SwiftUI
import Foundation

enum WidgetStatus {
    case notConnected
    case noSession
    case connecting
    case connected
    case error
}

struct QuickAccessItemModel {
    let thumbnail: Image
    let name: String
    let url: URL?
    let image: Image?
    let description: String?
}

enum QuickAccessWidgetAction: ActionType {
    case onWidgetReady
}

final class QuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadWidget
    }

    // MARK: - Private properties
    private let authUseCase: AuthUseCaseProtocol
    private let copyDataBasesUseCase: CopyDataBasesUseCaseProtocol
    private let offlineFilesUseCase: OfflineFilesUseCaseProtocol
    private let recentItemsUseCase: RecentItemsUseCaseProtocol
    private let favouriteItemsUseCase: FavouriteItemsUseCaseProtocol
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?

    init(authUseCase: AuthUseCaseProtocol, copyDataBasesUseCase: CopyDataBasesUseCaseProtocol, offlineFilesBasesUseCase: OfflineFilesUseCaseProtocol, recentItemsUseCase: RecentItemsUseCaseProtocol, favouriteItemsUseCase: FavouriteItemsUseCaseProtocol) {
        self.authUseCase = authUseCase
        self.copyDataBasesUseCase = copyDataBasesUseCase
        self.offlineFilesUseCase = offlineFilesBasesUseCase
        self.recentItemsUseCase = recentItemsUseCase
        self.favouriteItemsUseCase = favouriteItemsUseCase
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
    
    func fetchOfflineItems() -> EntryValue {
        if authUseCase.sessionId() != nil {
            let items = offlineFilesUseCase.offlineFiles().map {
                QuickAccessItemModel(thumbnail: imageForPatExtension(URL(fileURLWithPath: $0.localPath).pathExtension), name: URL(fileURLWithPath: $0.localPath).lastPathComponent, url: URL(string: SectionDetail.offline.link)?.appendingPathComponent($0.base64Handle), image: nil, description: nil)
            }
            return (items, .connected)
        } else {
            return ([], .noSession)
        }
    }
    
    func fetchRecentItems() -> EntryValue {
        if authUseCase.sessionId() != nil {
            let items = recentItemsUseCase.fetchRecentItems().map {
                QuickAccessItemModel(thumbnail: imageForPatExtension(URL(fileURLWithPath:$0.name).pathExtension), name: $0.name, url: URL(string: SectionDetail.recents.link)?.appendingPathComponent($0.base64Handle), image: $0.isUpdate ? Image("versioned") : Image("recentUpload"), description: recentStringTimestamp($0.timestamp))
            }
            return (items, .connected)
        } else {
            return ([], .noSession)
        }
    }
    
    func fetchFavouriteItems() -> EntryValue {
        if authUseCase.sessionId() != nil {
            let items = favouriteItemsUseCase.fetchFavouriteItems(upTo: MEGAQuickAccessWidgetMaxDisplayItems).map {
                QuickAccessItemModel(thumbnail: imageForPatExtension(URL(fileURLWithPath: $0.name).pathExtension), name: $0.name, url: URL(string: SectionDetail.favourites.link)?.appendingPathComponent($0.base64Handle), image: nil, description: nil)
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
            return Image(FileTypes().allTypes[pathExtension] ?? "generic")
        } else {
            return Image("folder")
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

        if let session = authUseCase.sessionId() {
            copyDataBasesUseCase.copyFromMainApp { (result) in
                switch result {
                case .success(_):
                    self.authUseCase.login(sessionId: session, delegate: MEGAGenericRequestDelegate { request, error in
                        if error.type != .apiOk {
                            MEGALogError("Widget Login error")
                            self.updateStatus(.error)
                        } else {
                            self.updateStatus(.connected)
                        }
                    })
                case .failure(_):
                    self.updateStatus(.error)
                }
            }
        } else {
            MEGALogError("Widget No session in the keychain")
            self.updateStatus(.noSession)
        }
    }
}
