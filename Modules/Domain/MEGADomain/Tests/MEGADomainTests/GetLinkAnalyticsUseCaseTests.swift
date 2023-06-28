import MEGADomain
import MEGADomainMock
import XCTest

final class GetLinkAnalyticsUseCaseTests: XCTestCase {

    func testSendEvent_setDecriptionKeyForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.sendDecriptionKey(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.sendDecriptionKeySeparateForFolder))
    }

    func testSendEvent_setDecriptionKeyForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.sendDecriptionKey(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.sendDecriptionKeySeparateForFile))
    }

    func testSendEvent_setExpiryDateForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.setExpiryDate(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.setExpiryDateForFolder))
    }

    func testSendEvent_setExpiryDateForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.setExpiryDate(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.setExpiryDateForFile))
    }

    func testSendEvent_setPasswordForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.setPassword(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.setPasswordForFolder))
    }

    func testSendEvent_setPasswordForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.setPassword(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.setPasswordForFile))
    }

    func testSendEvent_confirmPasswordForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.confirmPassword(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.confirmPaswordForFolder))
    }

    func testSendEvent_confirmPasswordForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.confirmPassword(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.confirmPasswordForFile))
    }

    func testSendEvent_resetPasswordForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.resetPassword(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.resetPasswordForFolder))
    }

    func testSendEvent_resetPasswordForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.resetPassword(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.resetPasswordForFile))
    }

    func testSendEvent_removePasswordForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.removePassword(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.removePasswordForFolder))
    }

    func testSendEvent_removePasswordForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.removePassword(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.removePasswordForFile))
    }

    func testSendEvent_shareLinkForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.shareLink(nodeTypes: [.folder])

        XCTAssertTrue(repo.type == .getLink(.shareFolder))
    }

    func testSendEvent_shareLinkForMultipleFolders_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.shareLink(nodeTypes: [.folder, .folder])

        XCTAssertTrue(repo.type == .getLink(.shareFolders))
    }

    func testSendEvent_shareLinkForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.shareLink(nodeTypes: [.file])

        XCTAssertTrue(repo.type == .getLink(.shareFile))
    }

    func testSendEvent_shareLinkForMultipleFiles_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.shareLink(nodeTypes: [.file, .file])

        XCTAssertTrue(repo.type == .getLink(.shareFiles))
    }

    func testSendEvent_shareLinkForMultipleFilesAndFolders_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.shareLink(nodeTypes: [.file, .folder])

        XCTAssertTrue(repo.type == .getLink(.shareFilesAndFolders))
    }

    func testSendEvent_getLinkForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.getLink(nodeTypes: [.folder])

        XCTAssertTrue(repo.type == .getLink(.getLinkForFolder))
    }

    func testSendEvent_getLinkForMultipleFolders_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.getLink(nodeTypes: [.folder, .folder])

        XCTAssertTrue(repo.type == .getLink(.getLinkForFolders))
    }

    func testSendEvent_getLinkForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.getLink(nodeTypes: [.file])

        XCTAssertTrue(repo.type == .getLink(.getLinkForFile))
    }

    func testSendEvent_getLinkForMultipleFiles_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.getLink(nodeTypes: [.file, .file])

        XCTAssertTrue(repo.type == .getLink(.getLinkForFiles))
    }

    func testSendEvent_getLinkForMultipleFilesAndFolders_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.getLink(nodeTypes: [.file, .folder])

        XCTAssertTrue(repo.type == .getLink(.getLinkForFilesAndFolders))
    }

    func testSendEvent_proFeatureSeePlansForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.proFeatureSeePlans(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.proFeaturesSeePlansFolder))
    }

    func testSendEvent_proFeatureSeePlansForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.proFeatureSeePlans(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.proFeaturesSeePlansFile))
    }

    func testSendEvent_proFeatureNotNowForFolder_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.proFeatureNotNow(nodeType: .folder)

        XCTAssertTrue(repo.type == .getLink(.proFeaturesNotNowFolder))
    }

    func testSendEvent_proFeatureNotNowForFile_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = GetLinkAnalyticsUseCase(repository: repo)

        usecase.proFeatureNotNow(nodeType: .file)

        XCTAssertTrue(repo.type == .getLink(.proFeaturesNotNowFile))
    }
}
