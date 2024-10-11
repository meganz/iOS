import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import UIKit

enum ManageChatHistorySection: Int {
    case historyRetention
    case clearChatHistory
}

enum HistoryRetentionRow: Int {
    case uiswitch
    case customTime
    case picker
}

enum HistoryRetentionOption: Int {
    case disabled
    case oneDay
    case oneWeek
    case oneMonth
    case custom
}

enum HistoryRetentionCustomOption: Int {
    case hours
    case days
    case weeks
    case months
    case year
}

enum PickerComponent: Int {
    case units
    case measurements
    case totalComponents
}

final class ManageChatHistoryTableViewController: UITableViewController, ViewType {
    // MARK: - Private properties
    
    @IBOutlet private weak var historyRetentionLabel: UILabel!
    @IBOutlet private weak var historyRetentionSwitch: UISwitch!
    
    @IBOutlet weak var historyRetentionCustomTableViewCell: UITableViewCell!
    @IBOutlet weak var historyRetentionCustomLabel: UILabel!
    @IBOutlet weak var historyRetentionSaveButton: UIButton!
    
    @IBOutlet weak var historyRetentionPickerTableViewCell: UITableViewCell!
    @IBOutlet weak var historyRetentionPickerView: UIPickerView!
    
    @IBOutlet private weak var clearAllChatHistoryLabel: UILabel!
    
    var router: ManageChatHistoryViewRouter!
    
    var viewModel: ManageChatHistoryViewModel!
    var pickerViewModel: HistoryRetentionPickerViewModel!
    
    private var historyRetentionFooter: String = ""
    private var clearChatHistoryFooter: String = ""
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        pickerViewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executePickerCommand(command) }
        }
        
        configView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let nav = navigationController {
                AppearanceManager.forceNavigationBarUpdate(nav.navigationBar, traitCollection: traitCollection)
            }
            
            updateAppearance()
        }
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: ManageChatHistoryViewModel.Command) {
        switch command {
        case .startLoading:
            SVProgressHUD.show()
            
        case .finishLoading:
            SVProgressHUD.dismiss()
            
        case .configHistoryRetentionSection(let historyRetentionOption, let historyRetentionValue):
            configHistoryRetentionSection(historyRetentionOption, historyRetentionValue)
        
        case .historyRetentionSwitch(let turnOn):
            historyRetentionSwitch.setOn(turnOn, animated: true)
            
        case .showHistoryRetentionActionSheet:
            historyRetentionActionSheet()
            
        case .showOrHideCustomHistoryRetentionCell(let isHidden):
            showCustomHistoryRetentionCell(isHidden: isHidden)
            tableView.reloadData()
            
        case .showOrHideHistoryRetentionPicker(let isHidden):
            showPicker(isHidden: isHidden)
            tableView.reloadData()
            
        case .configHistoryRetentionPicker(let historyRetentionValue):
            configPicker(historyRetentionValue)
            
        case .updateHistoryRetentionCustomLabel(let text):
            historyRetentionCustomLabel.text = text
            
        case .enableDisableSaveButton(let isEnabled):
            historyRetentionSaveButton.isEnabled = isEnabled
            
        case .showOrHideSaveButton(let isHidden):
            historyRetentionSaveButton.isHidden = isHidden
            
        case .updateHistoryRetentionFooter(let footer):
            historyRetentionFooter = footer
            
        case .showClearChatHistoryAlert:
            clearChatHistoryAlert()
            
        case .updateClearChatHistoryFooter(let footer):
            clearChatHistoryFooter = footer
            
        case .showResult(let resultCommand):
            executeCommand(resultCommand)
        }
    }
    
    func executeCommand(_ command: ManageChatHistoryViewModel.Command.ResultCommand) {
        switch command {
        case .success(let message):
            SVProgressHUD.showSuccess(withStatus: message)
            
        case .content(let image, let message):
            SVProgressHUD.show(image, status: message)
            
        case .error(let message):
            SVProgressHUD.showError(withStatus: message)
        }
    }
    
    func executePickerCommand(_ command: HistoryRetentionPickerViewModel.Command) {
        switch command {
        case .updateHistoryRetentionLabel(let historyRetentionString):
            historyRetentionCustomLabel.text = historyRetentionString
            historyRetentionSaveButton.isEnabled = true
            historyRetentionSaveButton.isHidden = false
            
        case .selectUnitPickerComponent(let unit):
            historyRetentionPickerView.selectRow(unit, inComponent: PickerComponent.units.rawValue, animated: false)
            
        case .selectMeasurementPickerComponent(let measurement):
            historyRetentionPickerView.selectRow(measurement, inComponent: PickerComponent.measurements.rawValue, animated: false)
        
        case .updateUnitPickerComponent:
            historyRetentionPickerView.reloadComponent(PickerComponent.units.rawValue)
            
        case .updateMeasurementPickerComponent:
            historyRetentionPickerView.reloadComponent(PickerComponent.measurements.rawValue)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func historyRetentionSwitchValueChanged(_ sender: UISwitch) {
        viewModel.dispatch(.historyRetentionSwitchValueChanged(sender.isOn))
    }
    
    @IBAction func historyRetentionSaveTouchUpInside(_ sender: UIButton) {
        viewModel.dispatch(.saveHistoryRetentionPickerValue(historyRetentionPickerView.selectedRow(inComponent: PickerComponent.units.rawValue), historyRetentionPickerView.selectedRow(inComponent: PickerComponent.measurements.rawValue)))
    }
    
    // MARK: - Private
    
    private func configView() {
        title = viewModel.navigationTitle
        
        historyRetentionLabel.text = Strings.Localizable.historyClearing
        viewModel.dispatch(.historyRetentionValue)
        
        historyRetentionSaveButton.setTitle(Strings.Localizable.save, for: .normal)
        
        historyRetentionPickerView.dataSource = pickerViewModel
        historyRetentionPickerView.delegate = pickerViewModel
        
        clearAllChatHistoryLabel.text = viewModel.clearHistoryTitle
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = .mnz_separator()
        
        historyRetentionCustomLabel.textColor = TokenColors.Support.success
        historyRetentionSaveButton.setTitleColor(TokenColors.Support.success, for: .normal)
        clearAllChatHistoryLabel.textColor = TokenColors.Text.error

        tableView.reloadData()
    }
    
    private func configHistoryRetentionSection(_ historyRetentionOption: HistoryRetentionOption, _ historyRetentionValue: UInt) {
        self.viewModel.dispatch(.historyRetentionFooter)
        switch historyRetentionOption {
        case .disabled:
            historyRetentionSwitch.setOn(false, animated: true)
            showCustomHistoryRetentionCell(isHidden: true)
            showPicker(isHidden: true)
            
        case .oneDay, .oneWeek, .oneMonth:
            historyRetentionSwitch.setOn(true, animated: true)
            showCustomHistoryRetentionCell(isHidden: true)
            showPicker(isHidden: true)
            
        case .custom:
            historyRetentionSwitch.setOn(true, animated: true)
            showCustomHistoryRetentionCell(isHidden: false)
            self.viewModel.dispatch(.historyRetentionCustomLabel(historyRetentionValue))
            
            if historyRetentionValue <= 0 {
                historyRetentionSaveButton.isHidden = false
                historyRetentionSaveButton.isEnabled = true
                
                showPicker(isHidden: false)
            } else {
                showPicker(isHidden: true)
                configPicker(historyRetentionValue)
            }
        }
        
        tableView.reloadData()
    }
    
    private func showCustomHistoryRetentionCell(isHidden: Bool) {
        historyRetentionCustomTableViewCell.isHidden = isHidden
    }
    
    private func showPicker(isHidden: Bool) {
        historyRetentionPickerTableViewCell.isHidden = isHidden
    }
    
    private func configPicker(_ historyRetentionValue: UInt) {
        pickerViewModel.dispatch(.configPicker(historyRetentionValue))
    }
    
    private func historyRetentionActionSheet() {
        let alertController = UIAlertController(title: Strings.Localizable.clearMessagesOlderThan, message: nil, preferredStyle: .actionSheet)
        
        let oneDayAction = UIAlertAction(title: Strings.Localizable.oneDay, style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.oneDay.rawValue))
        }
        
        let oneWeekAction = UIAlertAction(title: Strings.Localizable.oneWeek, style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.oneWeek.rawValue))
        }
        
        let oneMonthAction = UIAlertAction(title: Strings.Localizable.oneMonth, style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.oneMonth.rawValue))
        }
        
        let customAction = UIAlertAction(title: Strings.Localizable.custom, style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.custom.rawValue))
        }
        
        let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel) { _ in
            self.viewModel.dispatch(.configHistoryRetentionSwitch(false))
        }
        
        alertController.addAction(oneDayAction)
        alertController.addAction(oneWeekAction)
        alertController.addAction(oneMonthAction)
        alertController.addAction(customAction)
        alertController.addAction(cancelAction)
        
        if let popoverPC = alertController.popoverPresentationController {
            popoverPC.sourceView = historyRetentionSwitch
            popoverPC.sourceRect = historyRetentionSwitch.bounds
        }
        
        router.didTap(on: .historyRetentionSwitch(alertController))
    }
    
    private func clearChatHistoryAlert() {
        let alertController = UIAlertController(title: viewModel.clearHistoryTitle, message: viewModel.clearHistoryMessage, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil)
        
        let continueAction = UIAlertAction(title: Strings.Localizable.continue, style: .default) { _ in
            self.viewModel.dispatch(.clearChatHistoryConfirmed)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(continueAction)
        
        router.didTap(on: .clearChatHistoryAlert(alertController))
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case ManageChatHistorySection.historyRetention.rawValue:
            if (indexPath.row == HistoryRetentionRow.customTime.rawValue && historyRetentionCustomTableViewCell.isHidden) ||
                indexPath.row == HistoryRetentionRow.picker.rawValue  && historyRetentionPickerTableViewCell.isHidden {
                return 0
            }
        default:
            break
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case ManageChatHistorySection.historyRetention.rawValue:
            return historyRetentionFooter
            
        case ManageChatHistorySection.clearChatHistory.rawValue:
            self.viewModel.dispatch(.clearChatHistoryFooter)
            return clearChatHistoryFooter
            
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case ManageChatHistorySection.historyRetention.rawValue:
            if indexPath.row == HistoryRetentionRow.customTime.rawValue {
                viewModel.dispatch(.showOrHideHistoryRetentionPicker(!historyRetentionPickerTableViewCell.isHidden))
            }
        
        case ManageChatHistorySection.clearChatHistory.rawValue:
            viewModel.dispatch(.showClearChatHistoryAlert)
            
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
