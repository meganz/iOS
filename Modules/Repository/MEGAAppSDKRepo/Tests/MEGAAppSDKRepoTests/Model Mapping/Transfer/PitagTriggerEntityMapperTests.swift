import MEGADomain
import MEGASdk
import Testing

@Suite("PitagTriggerEntityMapperTests Mapper Tests")
struct PitagTriggerEntityMapperTests {
    
    @Test("Maps all PitagTriggerEntityMapperTests cases correctly", arguments: [
        (PitagTriggerEntity.notApplicable, MEGAPitagTrigger.notApplicable),
        (.picker, .picker),
        (.dragAndDrop, .dragAndDrop),
        (.camera, .camera),
        (.scanner, .scanner),
        (.shareFromApp, .shareFromApp),
        (.cameraCapture, .cameraCapture),
        (.explorerExtension, .explorerExtension),
        (.voiceRecorder, .voiceRecorder)
    ])
    func toMEGAPitagTrigger_allCases(entity: PitagTriggerEntity, expectedTarget: MEGAPitagTrigger) {
        let result = entity.toMEGAPitagTrigger()
        #expect(result == expectedTarget)
    }
}
