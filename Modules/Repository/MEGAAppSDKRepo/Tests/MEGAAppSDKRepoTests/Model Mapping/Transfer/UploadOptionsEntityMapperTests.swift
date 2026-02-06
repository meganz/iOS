import MEGADomain
import MEGASdk
import Testing

@Suite("UploadOptionsEntity Mapper Tests")
struct UploadOptionsEntityMapperTests {
    
    @Test("Maps UploadOptionsEntity with default values")
    func toMEGAUploadOptions_defaultValues() {
        let entity = UploadOptionsEntity()
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.fileName == nil)
        #expect(result.mtime == UploadOptionsEntity.invalidCustomModTime)
        #expect(result.appData == nil)
        #expect(result.isSourceTemporary == true)
        #expect(result.startFirst == false)
        #expect(result.pitagTrigger == .notApplicable)
        #expect(result.isChatUpload == false)
        #expect(result.pitagTarget == .notApplicable)
    }
    
    @Test("Maps UploadOptionsEntity with custom fileName")
    func toMEGAUploadOptions_withFileName() {
        let entity = UploadOptionsEntity(fileName: "CustomFile.jpg")
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.fileName == "CustomFile.jpg")
    }
    
    @Test("Maps UploadOptionsEntity with custom mtime")
    func toMEGAUploadOptions_withCustomMtime() {
        let customMtime: Int64 = 1234567890
        let entity = UploadOptionsEntity(mtime: customMtime)
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.mtime == customMtime)
    }
    
    @Test("Maps UploadOptionsEntity with appData")
    func toMEGAUploadOptions_withAppData() {
        let entity = UploadOptionsEntity(appData: "custom-app-data")
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.appData == "custom-app-data")
    }
    
    @Test("Maps UploadOptionsEntity with isSourceTemporary set to false")
    func toMEGAUploadOptions_withIsSourceTemporaryFalse() {
        let entity = UploadOptionsEntity(isSourceTemporary: false)
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.isSourceTemporary == false)
    }
    
    @Test("Maps UploadOptionsEntity with startFirst set to true")
    func toMEGAUploadOptions_withStartFirstTrue() {
        let entity = UploadOptionsEntity(startFirst: true)
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.startFirst == true)
    }
    
    @Test("Maps UploadOptionsEntity with isChatUpload set to true")
    func toMEGAUploadOptions_withIsChatUploadTrue() {
        let entity = UploadOptionsEntity(isChatUpload: true)
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.isChatUpload == true)
    }
    
    @Test("Maps all PitagTriggerEntity values correctly", arguments: [
        PitagTriggerEntity.notApplicable,
        .picker,
        .dragAndDrop,
        .camera,
        .scanner,
        .syncAlgorithm,
        .shareFromApp,
        .cameraCapture,
        .explorerExtension,
        .voiceRecorder
    ])
    func toMEGAUploadOptions_withPitagTrigger(trigger: PitagTriggerEntity) {
        let entity = UploadOptionsEntity(pitagTrigger: trigger)
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.pitagTrigger == trigger.toMEGAPitagTrigger())
    }
    
    @Test("Maps all PitagTargetEntity values correctly", arguments: [
        PitagTargetEntity.notApplicable,
        .cloudDrive,
        .chat1To1,
        .chatGroup,
        .noteToSelf,
        .incomingShare,
        .multipleChats
    ])
    func toMEGAUploadOptions_withPitagTarget(target: PitagTargetEntity) {
        let entity = UploadOptionsEntity(pitagTarget: target)
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.pitagTarget == target.toMEGAPitagTarget())
    }
    
    @Test("Maps UploadOptionsEntity with all properties set")
    func toMEGAUploadOptions_withAllProperties() {
        let entity = UploadOptionsEntity(
            fileName: "MyDocument.pdf",
            mtime: 9876543210,
            appData: "app-specific-data",
            isSourceTemporary: false,
            startFirst: true,
            pitagTrigger: .picker,
            isChatUpload: true,
            pitagTarget: .chatGroup
        )
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.fileName == "MyDocument.pdf")
        #expect(result.mtime == 9876543210)
        #expect(result.appData == "app-specific-data")
        #expect(result.isSourceTemporary == false)
        #expect(result.startFirst == true)
        #expect(result.pitagTrigger == .picker)
        #expect(result.isChatUpload == true)
        #expect(result.pitagTarget == .chatGroup)
    }
    
    @Test("Maps chat upload scenario correctly")
    func toMEGAUploadOptions_chatUploadScenario() {
        let entity = UploadOptionsEntity(
            fileName: "chat-image.jpg",
            pitagTrigger: .camera,
            isChatUpload: true,
            pitagTarget: .chat1To1
        )
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.fileName == "chat-image.jpg")
        #expect(result.pitagTrigger == .camera)
        #expect(result.isChatUpload == true)
        #expect(result.pitagTarget == .chat1To1)
    }
    
    @Test("Maps cloud drive upload scenario correctly")
    func toMEGAUploadOptions_cloudDriveUploadScenario() {
        let entity = UploadOptionsEntity(
            fileName: "backup.zip",
            isSourceTemporary: false,
            pitagTrigger: .dragAndDrop,
            pitagTarget: .cloudDrive
        )
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.fileName == "backup.zip")
        #expect(result.isSourceTemporary == false)
        #expect(result.pitagTrigger == .dragAndDrop)
        #expect(result.pitagTarget == .cloudDrive)
    }
    
    @Test("Maps temporary file upload scenario correctly")
    func toMEGAUploadOptions_temporaryFileScenario() {
        let entity = UploadOptionsEntity(
            isSourceTemporary: true,
            startFirst: true,
            pitagTrigger: .cameraCapture
        )
        let result = entity.toMEGAUploadOptions()
        
        #expect(result.isSourceTemporary == true)
        #expect(result.startFirst == true)
        #expect(result.pitagTrigger == .cameraCapture)
    }
}
