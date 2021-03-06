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
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if navigationController != nil {
                    AppearanceManager.forceNavigationBarUpdate(navigationController!.navigationBar, traitCollection: traitCollection)
                }
                
                updateAppearance()
            }
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
            break
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
        title = NSLocalizedString("Manage Chat History", comment: "Text related with the section where you can manage the chat history. There you can for example, clear the history or configure the retention setting.")
        
        historyRetentionLabel.text = NSLocalizedString("History Clearing", comment: "Setting title for the feature that deletes messages automatically from a chat after a period of time")
        viewModel.dispatch(.historyRetentionValue)
        
        historyRetentionSaveButton.setTitle(NSLocalizedString("save", comment: "Button title to 'Save' the selected option"), for: .normal)
        
        historyRetentionPickerView.dataSource = pickerViewModel
        historyRetentionPickerView.delegate = pickerViewModel
        
        clearAllChatHistoryLabel.text = NSLocalizedString("clearChatHistory", comment: "A button title to delete the history of a chat.")
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        historyRetentionCustomLabel.textColor = .mnz_turquoise(for: traitCollection)
        historyRetentionSaveButton.setTitleColor(.mnz_turquoise(for: traitCollection), for: .normal)
        
        clearAllChatHistoryLabel.textColor = .mnz_red(for: traitCollection)
        
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
        let alertController = UIAlertController(title: NSLocalizedString("Clear Messages Older Than", comment: "Title show on the sheet to configure default values of the 'History Retention' setting"), message: nil, preferredStyle: .actionSheet)
        
        let oneDayAction = UIAlertAction(title: NSLocalizedString("One Day", comment: "Used within the `Retention History` dropdown -- available option for the time range selection."), style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.oneDay.rawValue))
        }
        
        let oneWeekAction = UIAlertAction(title: NSLocalizedString("One Week", comment: "Used within the `Retention History` dropdown -- available option for the time range selection."), style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.oneWeek.rawValue))
        }
        
        let oneMonthAction = UIAlertAction(title: NSLocalizedString("One Month", comment: "Used within the `Retention History` dropdown -- available option for the time range selection."), style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.oneMonth.rawValue))
        }
        
        let customAction = UIAlertAction(title: NSLocalizedString("Custom...", comment: "Used within the `Retention History` dropdown -- opens the dialog providing the ability to specify custom time range."), style: .default) { _ in
            self.viewModel.dispatch(.selectHistoryRetentionValue(HistoryRetentionOption.custom.rawValue))
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: "Button title to cancel something"), style: .cancel) { _ in
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
        let alertController = UIAlertController(title: NSLocalizedString("clearChatHistory", comment: "A button title to delete the history of a chat."), message: NSLocalizedString("clearTheFullMessageHistory", comment: "A confirmation message for a user to confirm that they want to clear the history of a chat."), preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: "Button title to cancel something"), style: .cancel, handler: nil)
        
        let continueAction = UIAlertAction(title: NSLocalizedString("continue", comment: "'Next' button in a dialog"), style: .default) { _ in
            self.viewModel.dispatch(.clearChatHistoryConfirmed)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(continueAction)
        
        router.didTap(on: .clearChatHistoryAlert(alertController))
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var heightForRow: CGFloat = 0
        switch indexPath.section {
        case ManageChatHistorySection.historyRetention.rawValue:
            if indexPath.row == HistoryRetentionRow.uiswitch.rawValue {
                heightForRow = 44.0
            } else if indexPath.row == HistoryRetentionRow.customTime.rawValue {
                heightForRow = historyRetentionCustomTableViewCell.isHidden ? 0 : 44.0
            } else if indexPath.row == HistoryRetentionRow.picker.rawValue {
                heightForRow = historyRetentionPickerTableViewCell.isHidden ? 0 : 162.0
            }
            
        case ManageChatHistorySection.clearChatHistory.rawValue:
            heightForRow = 44.0
            
        default:
            heightForRow = 44.0
        }
        
        return heightForRow
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
