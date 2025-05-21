import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n

enum ManageHistoryAction: ActionType {
    case historyRetentionValue
    case configHistoryRetentionSwitch(Bool)
    case historyRetentionSwitchValueChanged(Bool)
    case selectHistoryRetentionValue(Int)
    
    case showOrHideCustomHistoryRetentionCell(Bool)
    case showOrHideHistoryRetentionPicker(Bool)
    case historyRetentionCustomLabel(UInt)
    case saveHistoryRetentionPickerValue(Int, Int)
    case historyRetentionFooter
    
    case showClearChatHistoryAlert
    case clearChatHistoryFooter
    case clearChatHistoryConfirmed
}

final class ManageChatHistoryViewModel: ViewModelType {
    enum Command: CommandType {
        case startLoading
        case finishLoading
        
        case configHistoryRetentionSection(HistoryRetentionOption, UInt)
        case historyRetentionSwitch(Bool)
        case showHistoryRetentionActionSheet
        
        case showOrHideCustomHistoryRetentionCell(Bool)
        case showOrHideHistoryRetentionPicker(Bool)
        case configHistoryRetentionPicker(UInt)
        case updateHistoryRetentionCustomLabel(String)
        case enableDisableSaveButton(Bool)
        case showOrHideSaveButton(Bool)
        case updateHistoryRetentionFooter(String)
        
        case showClearChatHistoryAlert
        case updateClearChatHistoryFooter(String)
        
        case showResult(ResultCommand)
        
        enum ResultCommand: Equatable {
            case success(String)
            case content(UIImage, String)
            case error(String)
        }
    }
    
    // MARK: - Private properties
    // MARK: UI Layer
    private let router: ManageChatHistoryViewRouter
    private let chatViewMode: ChatViewMode
    
    private var isChatTypeMeeting: Bool {
        switch chatViewMode {
        case .chats:
            return false
        case .meetings:
            return true
        }
    }
        
    // MARK: Domain Layer
    private let manageChatHistoryUseCase: ManageChatHistoryUseCase
    
    private let chatId: ChatIdEntity
    private var historyRetentionValue: UInt = 0
    
    private var historyRetentionOption = HistoryRetentionOption.disabled
    private var historyRetentionOptionSelected = HistoryRetentionOption.disabled
    
    // MARK: - Internal properties
    
    var invokeCommand: ((Command) -> Void)?
    var navigationTitle: String {
        return isChatTypeMeeting
            ? Strings.Localizable.Meetings.Info.manageMeetingHistory
            : Strings.Localizable.manageChatHistory
    }
    var clearHistoryTitle: String {
        return isChatTypeMeeting
            ? Strings.Localizable.Meetings.Info.ManageMeetingHistory.clearMeetingHistory
            : Strings.Localizable.clearChatHistory
    }
    var clearHistoryMessage: String {
        return isChatTypeMeeting
            ? Strings.Localizable.Meetings.Info.ManageMeetingHistory.clearMeetingHistoryMessage
            : Strings.Localizable.clearTheFullMessageHistory
    }
    
    // MARK: - Init
    
    init(router: ManageChatHistoryViewRouter,
         manageChatHistoryUseCase: ManageChatHistoryUseCase,
         chatId: ChatIdEntity,
         chatViewMode: ChatViewMode) {
        self.router = router
        self.manageChatHistoryUseCase = manageChatHistoryUseCase
        self.chatId = chatId
        self.chatViewMode = chatViewMode
    }
    
    // MARK: - Private
    
    private func historyRetentionPickerValueToUInt(_ unitsRow: Int, _ measurementsRow: Int) -> UInt {
        let hoursDaysWeeksMonthsOrYearValue = unitsRow + 1
        let secondsInYear = Int(truncatingIfNeeded: secondsInAYear)
        let measurement = [secondsInAHour, secondsInADay, secondsInAWeek, secondsInAMonth_30, secondsInYear][measurementsRow]
        let historyRetentionValue = hoursDaysWeeksMonthsOrYearValue * measurement
        
        return UInt(truncatingIfNeeded: historyRetentionValue)
    }
    
    private func setHistoryRetentionOption(_ historyRetentionValue: Int) {
        historyRetentionOptionSelected = HistoryRetentionOption(rawValue: historyRetentionValue) ?? HistoryRetentionOption(rawValue: 0)!
        
        switch historyRetentionValue {
        case HistoryRetentionOption.oneDay.rawValue:
            setHistoryRetention(UInt(secondsInADay))
        
        case HistoryRetentionOption.oneWeek.rawValue:
            setHistoryRetention(UInt(secondsInAWeek))
            
        case HistoryRetentionOption.oneMonth.rawValue:
            setHistoryRetention(UInt(secondsInAMonth_30))
            
        case HistoryRetentionOption.custom.rawValue:
            self.invokeCommand?(Command.showOrHideCustomHistoryRetentionCell(false))
            self.invokeCommand?(Command.showOrHideSaveButton(false))
            self.invokeCommand?(Command.enableDisableSaveButton(true))
            
            self.invokeCommand?(Command.showOrHideHistoryRetentionPicker(false))
            
        default: break
        }
    }
    
    private func setHistoryRetention(_ historyRetentionValue: UInt) {
        if historyRetentionValue == self.historyRetentionValue {
            if historyRetentionOptionSelected == .custom {
                self.invokeCommand?(.enableDisableSaveButton(false))
                self.invokeCommand?(.showOrHideSaveButton(true))
                
                self.invokeCommand?(.showOrHideHistoryRetentionPicker(true))
            }
            
            return
        } else {
            Task { [weak self] in
                guard let self else { return }
                do {
                    let period = try await manageChatHistoryUseCase.historyRetentionUseCase.setChatRetentionTime(for: chatId, period: historyRetentionValue)
                    self.historyRetentionValue = period
                    historyRetentionOption = historyRetentionOptionSelected
                
                    updateHistoryRetentionFooter()
                    
                    invokeCommand?(.configHistoryRetentionSection(historyRetentionOption, self.historyRetentionValue))
                    historyRetentionOptionSelected = .disabled
                } catch { 
                    
                }
            }
        }
    }
    
    private func historyRetentionOption(value: UInt) -> HistoryRetentionOption {
        let historyRetentionOption: HistoryRetentionOption
        if value <= 0 {
            historyRetentionOption = .disabled
        } else if value == secondsInADay {
            historyRetentionOption = .oneDay
        } else if value == secondsInAWeek {
            historyRetentionOption = .oneWeek
        } else if value == secondsInAMonth_30 {
            historyRetentionOption = .oneMonth
        } else {
            historyRetentionOption = .custom
        }
        
        return historyRetentionOption
    }
    
    private func updateHistoryRetentionFooter() {
        var footer: String
        switch historyRetentionOption {
        case .disabled:
            footer = Strings.Localizable.automaticallyDeleteMessagesOlderThanACertainAmountOfTime
            
        case .oneDay:
            footer = Strings.Localizable.automaticallyDeleteMessagesOlderThanOneDay
            
        case .oneWeek:
            footer = Strings.Localizable.automaticallyDeleteMessagesOlderThanOneWeek
            
        case .oneMonth:
            footer = Strings.Localizable.automaticallyDeleteMessagesOlderThanOneMonth
            
        case .custom:
            footer = Strings.Localizable.Chat.ManageHistory.Message.deleteMessageOlderThanCustomValue(NSString.mnz_hoursDaysWeeksMonthsOrYear(from: historyRetentionValue))
        }
        
        self.invokeCommand?(.updateHistoryRetentionFooter(footer))
    }
    
    private func updateClearChatHistoryFooter() {
        let footer = Strings.Localizable.DeleteAllMessagesAndFilesSharedInThisConversationFromBothParties.thisActionIsIrreversible
        
        self.invokeCommand?(.updateClearChatHistoryFooter(footer))
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: ManageHistoryAction) {
        switch action {
            
        case .historyRetentionValue:
            Task { [weak self] in
                guard let self else { return }
                do {
                    let currentHistoryRetentionValue = try await manageChatHistoryUseCase.retentionValueUseCase.chatRetentionTime(for: chatId)
                    historyRetentionValue = currentHistoryRetentionValue
                    historyRetentionOption = historyRetentionOption(value: currentHistoryRetentionValue)
                    invokeCommand?(.configHistoryRetentionSection(historyRetentionOption, currentHistoryRetentionValue))
                    
                    updateHistoryRetentionFooter()
                } catch { 
                    MEGALogError("Failed to get chat history retention value.")
                }
            }
            
        case .configHistoryRetentionSwitch(let on):
            self.invokeCommand?(Command.historyRetentionSwitch(on))
            
        case .historyRetentionSwitchValueChanged(let isOn):
            if isOn {
                self.invokeCommand?(Command.showHistoryRetentionActionSheet)
            } else {
                self.historyRetentionOptionSelected = .disabled
                setHistoryRetention(UInt(HistoryRetentionOption.disabled.rawValue))
                
                self.invokeCommand?(Command.configHistoryRetentionSection(.disabled, UInt(HistoryRetentionOption.disabled.rawValue)))
            }
            
        case .selectHistoryRetentionValue(let historyRetentionOption):
            setHistoryRetentionOption(historyRetentionOption)
            
        case .showOrHideCustomHistoryRetentionCell(let showOrHide):
            self.invokeCommand?(Command.showOrHideCustomHistoryRetentionCell(showOrHide))
            
        case .showOrHideHistoryRetentionPicker(let isHidden):
            // Since this action is dispatched only from the 'didSelectRowAt' from the VC, the picker has to be to be configured to its current value
            self.invokeCommand?(Command.configHistoryRetentionPicker(self.historyRetentionValue))
            
            self.invokeCommand?(Command.showOrHideHistoryRetentionPicker(isHidden))
            
        case .saveHistoryRetentionPickerValue(let unitsRow, let measurementRow):
            self.historyRetentionOptionSelected = .custom
            let historyRetentionValue = historyRetentionPickerValueToUInt(unitsRow, measurementRow)
            setHistoryRetention(historyRetentionValue)
            
            if historyRetentionValue != self.historyRetentionValue {
                self.updateHistoryRetentionFooter()
                self.invokeCommand?(.enableDisableSaveButton(false))
                self.invokeCommand?(.showOrHideSaveButton(true))
            }
            
        case .historyRetentionCustomLabel(let historyRetentionValue):
            self.invokeCommand?(.updateHistoryRetentionCustomLabel(NSString.mnz_hoursDaysWeeksMonthsOrYear(from: historyRetentionValue)))
        
        case .historyRetentionFooter:
            updateHistoryRetentionFooter()
            
        case .showClearChatHistoryAlert:
            self.invokeCommand?(Command.showClearChatHistoryAlert)
        
        case .clearChatHistoryConfirmed:
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await manageChatHistoryUseCase.clearChatHistoryUseCase.clearChatHistory(for: chatId)
                    let message = isChatTypeMeeting
                        ? Strings.Localizable.Meetings.Info.ManageMeetingHistory.meetingHistoryHasBeenCleared
                        : Strings.Localizable.chatHistoryHasBeenCleared
                    invokeCommand?(.showResult(.content(MEGAAssets.UIImage.clearChatHistory, message)))
                } catch { 
                    invokeCommand?(.showResult(.error(Strings.Localizable.AnErrorHasOccurred.theChatHistoryHasNotBeenSuccessfullyCleared)))
                }
            }
            
        case .clearChatHistoryFooter:
            updateClearChatHistoryFooter()
        }
    }
}
