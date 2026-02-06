import MEGADomain
import MEGASdk
import Testing

@Suite("PitagTargetEntity Mapper Tests")
struct PitagTargetEntityMapperTests {
    
    @Test("Maps all PitagTargetEntity cases correctly", arguments: [
        (PitagTargetEntity.notApplicable, MEGAPitagTarget.notApplicable),
        (.cloudDrive, .cloudDrive),
        (.chat1To1, .chat1To1),
        (.chatGroup, .chatGroup),
        (.noteToSelf, .noteToSelf),
        (.incomingShare, .incomingShare),
        (.multipleChats, .multipleChats)
    ])
    func toMEGAPitagTarget_allCases(entity: PitagTargetEntity, expectedTarget: MEGAPitagTarget) {
        let result = entity.toMEGAPitagTarget()
        #expect(result == expectedTarget)
    }
}
