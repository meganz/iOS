import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI

final class FavouritesQuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadWidget
    }

    // MARK: - Private properties
    private let credentialUseCase: any CredentialUseCaseProtocol
    private let copyDataBasesUseCase: any CopyDataBasesUseCaseProtocol
    private let favouriteItemsUseCase: any FavouriteItemsUseCaseProtocol
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?

    init(credentialUseCase: any CredentialUseCaseProtocol,
         copyDataBasesUseCase: any CopyDataBasesUseCaseProtocol,
         favouriteItemsUseCase: any FavouriteItemsUseCaseProtocol) {
        self.credentialUseCase = credentialUseCase
        self.copyDataBasesUseCase = copyDataBasesUseCase
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
    
    func fetchFavouriteItems() -> EntryValue {
        if credentialUseCase.hasSession() {
            let items = favouriteItemsUseCase.fetchFavouriteItems(upTo: MEGAQuickAccessWidgetMaxDisplayItems).map {
                QuickAccessItemModel(thumbnail: imageForPatExtension($0.name.pathExtension), name: $0.name, url: URL(string: SectionDetail.favourites.link)?.appendingPathComponent($0.base64Handle), image: nil, description: nil)
            }
            return (items, .connected)
        } else {
            return ([], .noSession)
        }
    }
    
    // MARK: - Private
    
    private func imageForPatExtension(_ pathExtension: String) -> Image {
        if pathExtension != "" {
            return MEGAAssetsImageProvider.fileTypeResource(forFileExtension: pathExtension)
        } else {
            return Image(.filetypeFolder)
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
