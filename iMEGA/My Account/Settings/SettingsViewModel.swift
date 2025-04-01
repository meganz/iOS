import MEGAAppPresentation
import MEGAL10n
import UIKit

enum SettingsAction: ActionType {
    case didSelect(section: Int, row: Int)
}

enum SettingsCommand: CommandType, Equatable {
    case reloadData
}

@objc class SettingsViewModel: NSObject, ViewModelType {

    private(set) var sectionViewModels = [SettingSectionViewModel]()
    let router: SettingViewRouter
    
    init(router: SettingViewRouter, sections: [SettingSectionViewModel]) {
        self.router = router
        self.sectionViewModels = sections
        super.init()
    }
    
    var invokeCommand: ((SettingsCommand) -> Void)?
    
    func dispatch(_ action: SettingsAction) {
        switch action {
        case .didSelect(section: let section, row: let row):
            if let selectedCell = cellViewModel(at: section, in: row) {
                selectedCell.router?.start()
            }
        }
    }
    
    func numberOfSections() -> Int {
        sectionViewModels.count
    }
    
    func numberOfRows(in section: Int) -> Int {
        sectionViewModels.indices.contains(section) ? sectionViewModels[section].cellViewModels.count : 0
    }
    
    func cellViewModel(at section: Int, in row: Int) -> SettingCellViewModel? {
        if sectionViewModels.indices.contains(section) {
            if sectionViewModels[section].cellViewModels.indices.contains(row) {
                return sectionViewModels[section].cellViewModels[row]
            }
        }
        return nil
    }
    
    func reloadData() {
        invokeCommand?(.reloadData)
    }
}

extension CameraUploadManager {
    static func getCameraUploadStatus() -> String {
        isCameraUploadEnabled ? Strings.Localizable.on : Strings.Localizable.off
    }
}
