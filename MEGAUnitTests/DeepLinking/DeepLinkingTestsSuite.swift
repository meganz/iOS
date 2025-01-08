@testable import MEGA
import Testing

@Suite("Deep Linking Tests Suite - Tests various types of deep links and their expected behavior.")
struct DeepLinkingTestSuite {
    
    // MARK: - Helpers
    private static func assertDeepLinkType(
        urlString: String,
        expectedType: URLType
    ) {
        guard let url = URL(string: urlString) as? NSURL else {
            Issue.record("Invalid URL string: \(urlString)")
            return
        }
        #expect(url.mnz_type() == expectedType, "Expected \(expectedType) but got \(url.mnz_type()) for URL: \(urlString)")
    }

    // MARK: - File Link Tests
    @Suite("File Link Tests - Verifies correct type is returned for file-related URLs.")
    struct FileLinkTests {
        @Test("File Link NSURL should return .fileLink", arguments: [
            "https://mega.nz/file/paBmgYJQ#sL6x-6LcvZEV6R4JxOuNI6I-0NKB5LcMoQnM-7Qw1Os",
            "https://testbed.preview.mega.co.nz/file/cNpAEKLS#B7T0WMhV38wOUkEUBRy6eej46wWJo0NKQC2Hz3wW0jc",
            "mega://#!paBmgYJQ!sL6x-6LcvZEV6R4JxOuNI6I-0NKB5LcMoQnM-7Qw1Os",
            "https://mega.nz/file/paBmgYJQ?a=sdf&b=123#sL6x-6LcvZEV6R4JxOuNI6I-0NKB5LcMoQnM-7Qw1Os"
        ])
        func fileLinkShouldReturnFileLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .fileLink)
        }
    }

    // MARK: - File Request Link Tests
    @Suite("File Request Link Tests - Verifies correct type is returned for file request URLs.")
    struct FileRequestLinkTests {
        @Test("File Request NSURL should return .fileRequestLink", arguments: [
            "https://mega.nz/filerequest/7W2qzsGbNpU"
        ])
        func fileRequestLinkShouldReturnFileRequestLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .fileRequestLink)
        }
    }

    // MARK: - Schedule Chat Link Tests
    @Suite("Schedule Chat Link Tests - Verifies correct type is returned for chat scheduling URLs.")
    struct ScheduleChatLinkTests {
        @Test("Schedule Chat NSURL should return .scheduleChatLink", arguments: [
            "https://help.mega.io/chats-meetings/meetings/schedule-oneoff-recurring-meeting"
        ])
        func scheduleChatLinkShouldReturnScheduleChatLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .scheduleChatLink)
        }
    }

    // MARK: - Folder Link Tests
    @Suite("Folder Link Tests - Verifies correct type is returned for folder-related URLs.")
    struct FolderLinkTests {
        @Test("Folder Link NSURL should return .folderLink", arguments: [
            "https://testbed.preview.mega.co.nz/folder/1dICRLJS#snJiad_4WfCKEK7bgPri3A",
            "https://mega.nz/folder/1dICRLJS#snJiad_4WfCKEK7bgPri3A",
            "mega://#F!1dICRLJS!snJiad_4WfCKEK7bgPri3A!0ch3QSwA",
            "https://mega.nz/folder/1dICRLJS?a=sdf&b=123#snJiad_4WfCKEK7bgPri3A"
        ])
        func folderLinkShouldReturnFolderLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .folderLink)
        }
    }

    // MARK: - Encrypted Link Tests
    @Suite("Encrypted Link Tests - Verifies correct type is returned for encrypted URLs.")
    struct EncryptedLinkTests {
        @Test("Encrypted NSURL should return .encryptedLink", arguments: [
            "https://mega.nz/#P!AgGaA3GQAEBzfpgzeA4GC-CwSRMY0TpxxG6fXPmuUMcsVr2vDnSQYoS0K50PRR5Uh7HjyI2u56t_Lv_AkVRld5-c_rvBFoaqokLtTOz-ELFYE1BgAlhjKcPe3q8iicg9sUPDNjXYzH4",
            "https://mega.nz/?a=sdf&b=123#P!AgGaA3GQAEBzfpgzeA4GC-CwSRMY0TpxxG6fXPmuUMcsVr2vDnSQYoS0K50PRR5Uh7HjyI2u56t_Lv_AkVRld5-c_rvBFoaqokLtTOz-ELFYE1BgAlhjKcPe3q8iicg9sUPDNjXYzH4"
        ])
        func encryptedLinkShouldReturnEncryptedLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .encryptedLink)
        }
    }

    // MARK: - Confirmation Link Tests
    @Suite("Confirmation Link Tests - Verifies correct type is returned for confirmation URLs.")
    struct ConfirmationLinkTests {
        @Test("Confirmation NSURL should return .confirmationLink", arguments: [
            "https://mega.nz/confirmQ29uZmlybUNvZGVWMr-2MuOxBAAEFCHyYDarFmhsKzA0MTlAbWVnYS5jby5ueglwZXRlciBsaesszDn6UKiJ",
            "https://mega.nz/confirm?a=sdf&b=123",
            "https://mega.nz/#confirmQ29uZmlybUNvZGVWMr-2MuOxBAAEFCHyYDarFmhsKzA0MTlAbWVnYS5jby5ueglwZXRlciBsaesszDn6UKiJ"
        ])
        func confirmationLinkShouldReturnConfirmationLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .confirmationLink)
        }
    }

    // MARK: - Open In Link Tests
    @Suite("Open In Link Tests - Verifies correct type is returned for open-in URLs.")
    struct OpenInLinkTests {
        @Test("Open In NSURL should return .openInLink", arguments: [
            "file:///"
        ])
        func openInLinkShouldReturnOpenInLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .openInLink)
        }
    }

    // MARK: - New Sign Up Link Tests
    @Suite("New Sign Up Link Tests - Verifies correct type is returned for sign-up URLs.")
    struct NewSignUpLinkTests {
        @Test("New Sign Up NSURL should return .newSignUpLink", arguments: [
            "https://mega.nz/newsignup",
            "https://mega.nz/newsignup?a=sdf&b=123",
            "https://mega.nz/#newsignup",
            "https://mega.nz/?a=sdf&b=123#newsignup"
        ])
        func newSignUpLinkShouldReturnNewSignUpLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .newSignUpLink)
        }
    }

    // MARK: - Backup Link Tests
    @Suite("Backup Link Tests - Verifies correct type is returned for backup URLs.")
    struct BackupLinkTests {
        @Test("Backup NSURL should return .backupLink", arguments: [
            "https://mega.nz/backup",
            "https://mega.nz/backup?a=sdf&b=123",
            "https://mega.nz/#backup",
            "https://mega.nz/?a=sdf&b=123#backup"
        ])
        func backupLinkShouldReturnBackupLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .backupLink)
        }
    }

    // MARK: - Incoming Pending Contacts Link Tests
    @Suite("Incoming Pending Contacts Link Tests - Verifies correct type is returned for IPC URLs.")
    struct IncomingPendingContactsLinkTests {
        @Test("Incoming Pending Contacts NSURL should return .incomingPendingContactsLink", arguments: [
            "https://mega.nz/fm/ipc",
            "https://mega.nz/fm/ipc?a=sdf&b=123",
            "https://mega.nz/#fm/ipc",
            "https://mega.nz/?a=sdf&b=123#fm/ipc"
        ])
        func incomingPendingContactsLinkShouldReturnIPCLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .incomingPendingContactsLink)
        }
    }

    // MARK: - Change Email Link Tests
    @Suite("Change Email Link Tests - Verifies correct type is returned for change email URLs.")
    struct ChangeEmailLinkTests {
        @Test("Change Email NSURL should return .changeEmailLink", arguments: [
            "https://mega.nz/verify",
            "https://mega.nz/verify?a=sdf&b=123",
            "https://mega.nz/#verify",
            "https://mega.nz/?a=sdf&b=123#verify"
        ])
        func changeEmailLinkShouldReturnChangeEmailLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .changeEmailLink)
        }
    }

    // MARK: - Cancel Account Link Tests
    @Suite("Cancel Account Link Tests - Verifies correct type is returned for cancel account URLs.")
    struct CancelAccountLinkTests {
        @Test("Cancel Account NSURL should return .cancelAccountLink", arguments: [
            "https://mega.nz/cancel",
            "https://mega.nz/cancel?a=sdf&b=123",
            "https://mega.nz/#cancel",
            "https://mega.nz/?a=sdf&b=123#cancel"
        ])
        func cancelAccountLinkShouldReturnCancelAccountLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .cancelAccountLink)
        }
    }

    // MARK: - Recover Link Tests
    @Suite("Recover Link Tests - Verifies correct type is returned for recover URLs.")
    struct RecoverLinkTests {
        @Test("Recover NSURL should return .recoverLink", arguments: [
            "https://mega.nz/recover",
            "https://mega.nz/recoveryxqwefdsfd"
        ])
        func recoverLinkShouldReturnRecoverLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .recoverLink)
        }
    }

    // MARK: - Contact Link Tests
    @Suite("Contact Link Tests - Verifies correct type is returned for contact URLs.")
    struct ContactLinkTests {
        @Test("Contact NSURL should return .contactLink", arguments: [
            "https://mega.nz/C!",
            "https://mega.nz/C!?a=sdf&b=123",
            "https://mega.nz/#C!",
            "https://mega.nz/?a=sdf&b=123#C!"
        ])
        func contactLinkShouldReturnContactLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .contactLink)
        }
    }

    // MARK: - Open Chat Section Link Tests
    @Suite("Open Chat Section Link Tests - Verifies correct type is returned for chat-related URLs.")
    struct OpenChatSectionLinkTests {
        @Test("Open Chat Section NSURL should return .openChatSectionLink", arguments: [
            "https://mega.nz/fm/chat",
            "https://mega.nz/fm/chat?a=sdf&b=123",
            "https://mega.nz/#fm/chat",
            "https://mega.nz/?a=sdf&b=123#fm/chat"
        ])
        func openChatSectionLinkShouldReturnOpenChatSectionLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .openChatSectionLink)
        }
    }

    // MARK: - Public Chat Link Tests
    @Suite("Public Chat Link Tests - Verifies correct type is returned for public chat URLs.")
    struct PublicChatLinkTests {
        @Test("Public Chat NSURL should return .publicChatLink", arguments: [
            "https://mega.nz/chat/X1FRRCaL#a7qjLayRnqR0fFHpov8DrA",
            "mega://chat/5LpjxQAa#N_fC9cHlBXXWdbfpWQHrRg",
            "https://mega.nz/chat/X1FRRCaL?a=sdf&b=123#a7qjLayRnqR0fFHpov8DrA"
        ])
        func publicChatLinkShouldReturnPublicChatLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .publicChatLink)
        }
    }

    // MARK: - Login Required Link Tests
    @Suite("Login Required Link Tests - Verifies correct type is returned for login-required URLs.")
    struct LoginRequiredLinkTests {
        @Test("Login Required NSURL should return .loginRequiredLink", arguments: [
            "https://mega.nz/loginrequired",
            "https://mega.nz/loginrequired?a=sdf&b=123"
        ])
        func loginRequiredLinkShouldReturnLoginRequiredLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .loginRequiredLink)
        }
    }

    // MARK: - Handle Link Tests
    @Suite("Handle Link Tests - Verifies correct type is returned for handle-related URLs.")
    struct HandleLinkTests {
        @Test("Handle NSURL should return .handleLink", arguments: [
            "https://mega.nz/#sdfsdsdf",
            "https://mega.nz/?a=sdf&b=123#sdfsdsdf"
        ])
        func handleLinkShouldReturnHandleLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .handleLink)
        }
    }

    // MARK: - Achievements Link Tests
    @Suite("Achievements Link Tests - Verifies correct type is returned for achievements URLs.")
    struct AchievementsLinkTests {
        @Test("Achievements NSURL should return .achievementsLink", arguments: [
            "https://mega.nz/achievements",
            "https://mega.nz/achievements?a=sdf&b=123"
        ])
        func achievementsLinkShouldReturnAchievementsLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .achievementsLink)
        }
    }

    // MARK: - New Text File Link Tests
    @Suite("New Text File Link Tests - Verifies correct type is returned for new text file URLs.")
    struct NewTextFileLinkTests {
        @Test("New Text File NSURL should return .newTextFile", arguments: [
            "https://mega.nz/newText",
            "https://mega.nz/newText?a=sdf&b=123"
        ])
        func newTextFileLinkShouldReturnNewTextFileType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .newTextFile)
        }
    }

    // MARK: - Default Link Tests
    @Suite("Default Link Tests - Verifies that unrelated URLs return .default.")
    struct DefaultLinkTests {
        @Test("Default NSURL should return .default", arguments: [
            "https://mega.nz/privacy",
            "https://mega.nz/privacy?a=sdf&b=123",
            "https://mega.nz/cookie",
            "https://mega.nz/cookie?a=sdf&b=123",
            "https://mega.nz/terms",
            "https://mega.nz/terms?a=sdf&b=123",
            "https://example.com/data.csv#row=4",
            "https://mega.nz/recovery"
        ])
        func defaultLinkShouldReturnDefaultType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .default)
        }
    }

    // MARK: - App Settings Link Tests
    @Suite("App Settings Link Tests - Verifies correct type is returned for app settings URLs.")
    struct AppSettingsLinkTests {
        @Test("App Settings NSURL should return .appSettings", arguments: [
            UIApplication.openSettingsURLString
        ])
        func appSettingsLinkShouldReturnAppSettingsType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .appSettings)
        }
    }

    // MARK: - Collection Link Tests
    @Suite("Collection Link Tests - Verifies correct type is returned for collection URLs.")
    struct CollectionLinkTests {
        @Test("Collection NSURL should return .collection", arguments: [
            "https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA",
            "mega://collection/p3IBQCiZ#Nt8-bopPB8em4cOlKFqStA"
        ])
        func collectionLinkShouldReturnCollectionType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .collection)
        }
    }

    // MARK: - Recover Link Edge Case Tests
    @Suite("Recover Link Edge Case Tests - Verifies recovery-related edge cases.")
    struct RecoverLinkEdgeCaseTests {
        @Test("Recover NSURL containing 'recovery' should return .recoverLink", arguments: [
            "https://mega.nz/recoveryxqwefdsfd"
        ])
        func recoverLinkWithRecoveryInPathShouldReturnRecoverLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .recoverLink)
        }
    }

    // MARK: - Upgrade Link Tests
    @Suite("Upgrade Link Tests - Verifies correct type is returned for upgrade URLs.")
    struct UpgradeLinkTests {
        @Test("Upgrade NSURL should return .upgrade", arguments: [
            "mega://upgrade"
        ])
        func upgradeLinkShouldReturnUpgradeLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .upgrade)
        }
    }
    
    // MARK: - App Links Tests
    @Suite("Specialized App Links Tests - Verifies links for VPN and PWM.")
    struct SpecializedAppLinksTests {
        @Test("VPN and PWM NSURL should return correct types", arguments: [
            ("mega://vpn", URLType.vpn),
            ("mega://pwm", URLType.pwm)
        ])
        func specializedAppLinksShouldReturnCorrectType(url: String, expectedType: URLType) {
            assertDeepLinkType(urlString: url, expectedType: expectedType)
        }
    }
    
    // MARK: - Camera Uploads Settings Link Tests
    @Suite("Camera Uploads Settings Link Tests - Verifies correct type is returned for Camera Uploads Settings URLs.")
    struct CUSettingsLinkTests {
        @Test("Camera Uploads Settings NSURL should return .cameraUploadsSettings", arguments: [
            "mega://settings/camera"
        ])
        func cuSettingsLinkShouldReturnUpgradeLinkType(url: String) {
            assertDeepLinkType(urlString: url, expectedType: .cameraUploadsSettings)
        }
    }
}
