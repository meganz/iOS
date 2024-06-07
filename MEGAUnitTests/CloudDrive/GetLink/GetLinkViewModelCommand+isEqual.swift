import Foundation
@testable import MEGA

extension GetLinkViewModelCommand {
    
    static func == (lhs: GetLinkViewModelCommand, rhs: GetLinkViewModelCommand) -> Bool {
        let conditions: [Bool] = switch (lhs, rhs) {
        case let (.configureView(lhsTitle, lhsIsMultiLink, lhsShareButtonTitle), .configureView(rhsTitle, rhsIsMultiLink, rhsShareButtonTitle)):
            [lhsTitle == rhsTitle, lhsIsMultiLink == rhsIsMultiLink, lhsShareButtonTitle == rhsShareButtonTitle]
        case
            let (.reloadSections(lhsIndexSet), .reloadSections(rhsIndexSet)),
            let (.deleteSections(lhsIndexSet), .deleteSections(rhsIndexSet)),
            let (.insertSections(lhsIndexSet), .insertSections(rhsIndexSet)):
            [lhsIndexSet == rhsIndexSet]
        case let (.reloadRows(lhsIndexPaths), .reloadRows(rhsIndexPaths)):
            [lhsIndexPaths == rhsIndexPaths]
        case let (.configureToolbar(lhsIsDecryptionKeySeparate), .configureToolbar(rhsIsDecryptionKeySeparate)):
            [lhsIsDecryptionKeySeparate == rhsIsDecryptionKeySeparate]
        case let (.showHud(lhsMessageType), .showHud(rhsMessageType)):
            [lhsMessageType == rhsMessageType]
        case let (.addToPasteBoard(lshMessage), .addToPasteBoard(rshMessage)):
            [lshMessage == rshMessage]
        case let (.showShareActivity(lhsSender, lhsLink, lhsKey), .showShareActivity(rhsSender, rhsLink, rhsKey)):
            [lhsSender == rhsSender, lhsLink == rhsLink, lhsKey == rhsKey]
        case
            (.enableLinkActions, .enableLinkActions),
            (.hideMultiLinkDescription, .hideMultiLinkDescription),
            (.dismissHud, .dismissHud),
            (.dismiss, .dismiss):
            [true]
        case let (.showAlert(lhs), .showAlert(rhs)):
            [lhs.title == rhs.title, lhs.message == rhs.message, lhs.actions == rhs.actions]
        default:
            [false]
        }
        return conditions.allSatisfy { $0 }
    }
}
