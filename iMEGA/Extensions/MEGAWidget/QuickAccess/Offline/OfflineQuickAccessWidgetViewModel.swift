import Foundation
import SwiftUI

final class OfflineQuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadWidget
    }

    // MARK: - Private properties
    private let authUseCase: AuthUseCaseProtocol
    private let copyDataBasesUseCase: CopyDataBasesUseCaseProtocol
    private let offlineFilesUseCase: OfflineFilesUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?

    init(authUseCase: AuthUseCaseProtocol, copyDataBasesUseCase: CopyDataBasesUseCaseProtocol, offlineFilesBasesUseCase: OfflineFilesUseCaseProtocol) {
        self.authUseCase = authUseCase
        self.copyDataBasesUseCase = copyDataBasesUseCase
        self.offlineFilesUseCase = offlineFilesBasesUseCase
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
    
    //MARK: -Private
    
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
