@testable import MEGA
import MEGADomain
import Testing

@MainActor
@Suite("TransfersTableViewCellViewModel Tests Suite - Verifies formatting logic in legacy transfers cell VM")
struct TransfersTableViewCellViewModelTests {
    
    // MARK: - Text Formatting Tests Suite
    @MainActor @Suite("Text Formatting Tests Suite")
    struct TextFormattingTests {
        @Test func percentageCompletedString_withArabicLocalizedFormat_reordersAndFormatsValues() {
            let transfer = TransferEntity(totalBytes: 1_048_576)
            let text = TransferTableViewCellViewModel.percentageCompletedString(
                transferEntity: transfer,
                percentage: 0.95,
                localizedFormat: "[A] من [B]"
            )
            
            let fileSize = String.memoryStyleString(fromByteCount: 1_048_576)
            #expect(text == "95 % من \(fileSize)")
        }
        
        @Test func percentageCompletedString_withZeroPercentage_formatsZero() {
            let transfer = TransferEntity(totalBytes: 1_024)
            let text = TransferTableViewCellViewModel.percentageCompletedString(
                transferEntity: transfer,
                percentage: 0,
                localizedFormat: "[A] of [B]"
            )
            
            let fileSize = String.memoryStyleString(fromByteCount: 1_024)
            #expect(text == "0 % of \(fileSize)")
        }
    }

}
