import MEGAAppSDKRepo
import MEGADomain
import Testing

@Suite("Event entity type mapper test suite")
struct EventEntityTypeMapperTests {
    /// The SDK's `MegaEvent::EVENT_TRANSFER_QUOTA_STATE`.
    @Test("Transfer quota state maps to its SDK event code")
    func transferQuotaStateMapsToItsCode() {
        #expect(EventEntity.EventType.transferQuotaState.code == 26)
    }
}
