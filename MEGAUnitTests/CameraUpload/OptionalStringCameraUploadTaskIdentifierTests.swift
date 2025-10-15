@testable import MEGA
import Testing

struct OptionalStringCameraUploadTaskIdentifierTests {

    @Test
    func parsedInfo() async throws {
        let localIdentifier: String = "A783021E-5B62-4178-BA1A-B8E8EF1B8CF1L0001,8"
        let taskDescription: String? = "\(localIdentifier)|\(0)|\(1)"
        
        #expect(taskDescription.localIdentifier() == localIdentifier)
    }

    @Test func noParsedInfo() {
        let taskDescription: String? = "A783021E-5B62-4178-BA1A-B8E8EF1B8CF1L0001,8"
        #expect(taskDescription.localIdentifier() == taskDescription)
    }
}
