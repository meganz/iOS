import MEGADomain

extension GetLinkAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .sendDecriptionKeySeparateForFolder:
            return 402001
        case .sendDecriptionKeySeparateForFile:
            return 402002
        case .setExpiryDateForFolder:
            return 402003
        case .setExpiryDateForFile:
            return 402004
        case .setPasswordForFolder:
            return 402005
        case .setPasswordForFile:
            return 402006
        case .confirmPaswordForFolder:
            return 402007
        case .confirmPasswordForFile:
            return 402008
        case .resetPasswordForFolder:
            return 402009
        case .resetPasswordForFile:
            return 402010
        case .removePasswordForFile:
            return 402011
        case .removePasswordForFolder:
            return 402012
        case .shareFolder:
            return 402013
        case .shareFolders:
            return 402014
        case .shareFile:
            return 402015
        case .shareFiles:
            return 402016
        case .shareFilesAndFolders:
            return 402017
        case .getLinkForFolder:
            return 402018
        case .getLinkForFolders:
            return 402019
        case .getLinkForFile:
            return 402020
        case .getLinkForFiles:
            return 402021
        case .getLinkForFilesAndFolders:
            return 402022
        case .proFeaturesSeePlansFolder:
            return 402023
        case .proFeaturesNotNowFolder:
            return 402024
        case .proFeaturesSeePlansFile:
            return 402025
        case .proFeaturesNotNowFile:
            return 402026
        }
    }

    var description: String {
        switch self {
        case .sendDecriptionKeySeparateForFolder:
            return "Send decription key separate toggled for folder"
        case .sendDecriptionKeySeparateForFile:
            return "Send decription key separate toggled for file"
        case .setExpiryDateForFolder:
            return "Set expiry date for folder"
        case .setExpiryDateForFile:
            return "Set expiry date for file"
        case .setPasswordForFolder:
            return "Set password for folder"
        case .setPasswordForFile:
            return "Set password for file"
        case .confirmPaswordForFolder:
            return "Confirm password for folder"
        case .confirmPasswordForFile:
            return "Confirm password for file"
        case .resetPasswordForFolder:
            return "Reset password tapped for folder"
        case .resetPasswordForFile:
            return "Reset password tapped for file"
        case .removePasswordForFolder:
            return "Remove password tapped for folder"
        case .removePasswordForFile:
            return "Remove password tapped for file"
        case .shareFolder:
            return "Share link tapped for folder"
        case .shareFolders:
            return "Share link tapped multiple folders"
        case .shareFile:
            return "Share link tapped for file"
        case .shareFiles:
            return "Share link tapped for multiple files"
        case .shareFilesAndFolders:
            return "Share links tapped for multiple files and folders"
        case .getLinkForFolder:
            return "Manage link tapped for folder"
        case .getLinkForFolders:
            return "Manage link tapped for folders"
        case .getLinkForFile:
            return "Manage link tapped for file"
        case .getLinkForFiles:
            return "Manage link tapped for files"
        case .getLinkForFilesAndFolders:
            return "Manage link tapped for multiple files and folders"
        case .proFeaturesSeePlansFolder:
            return "Pro feature see plans tapped for folder"
        case .proFeaturesNotNowFolder:
            return "Pro feature see plans not now tapped for folder"
        case .proFeaturesSeePlansFile:
            return "Pro feature see plans tapped for file"
        case .proFeaturesNotNowFile:
            return "Pro feature see plans not now tapped for file"
        }
    }
}
