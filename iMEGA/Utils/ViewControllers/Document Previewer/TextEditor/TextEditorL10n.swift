enum TextEditorL10n {
    static let close = NSLocalizedString("close", comment:"A button label.")
    static let cancel = NSLocalizedString("cancel", comment:"Button title to cancel something")
    static let save = NSLocalizedString("save", comment:"Button title to 'Save' the selected option")
    static let rename = NSLocalizedString("rename", comment:"Title for the action that allows you to rename a file or folder")
    static let renameAlertMessage = NSLocalizedString("renameNodeMessage", comment:"Hint text to suggest that the user have to write the new name for the file or folder")
    static let duplicateNameAlertMessage = NSLocalizedString("There is already a file with the same name", comment:"A tooltip message which shows when a file name is duplicated during renaming.")
    static let duplicateNameAlertTitle = NSLocalizedString("rename_file_alert_title", comment:"Alert title to ask if user want to rename the file.")
    static let replace = NSLocalizedString("replace", comment:"Title for the action that allows you to replace a file.")
    static let textFile = NSLocalizedString(
        "new_text_file", comment:
        "Menu option from the `Add` section that allows the user to create a new text file and upload it directly to MEGA"
    )
    static let fileName = NSLocalizedString(
        "file_name", comment:
        "Hint text shown on the new text file alert."
    )
    static let create = NSLocalizedString(
        "createFolderButton", comment:
        "Title button for the create folder alert."
    )
    static let transferError = NSLocalizedString("Transfer failed:", comment: "Notification message shown when a transfer failed. Keep colon.")
    static let upload = NSLocalizedString("upload", comment: "")
    static let download = NSLocalizedString("download", comment: "")
}
