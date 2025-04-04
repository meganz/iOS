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
            return 402012
        case .removePasswordForFolder:
            return 402011
        case .shareFolder:
            return 402013
        case .shareFile:
            return 402014
        case .shareMultipleNodes:
            return 402022
        case .getLinkForFolder:
            return 402015
        case .getLinkForFile:
            return 402016
        case .getLinkMultipleNodes:
            return 402021
        case .proFeaturesSeePlansFolder:
            return 402017
        case .proFeaturesNotNowFolder:
            return 402019
        case .proFeaturesSeePlansFile:
            return 402018
        case .proFeaturesNotNowFile:
            return 402020
        }
    }

    var description: String {
        switch self {
        case .sendDecriptionKeySeparateForFolder:
            return "Send decryption key separately folder"
        case .sendDecriptionKeySeparateForFile:
            return "Send decryption key separately file"
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
        case .shareFile:
            return "Share link tapped for file"
        case .shareMultipleNodes:
            return "Share link for multiple Nodes"
        case .getLinkForFolder:
            return "Manage link tapped for folder"
        case .getLinkForFile:
            return "Manage link tapped for file"
        case .getLinkMultipleNodes:
            return "Manage link for multiple Nodes"
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
