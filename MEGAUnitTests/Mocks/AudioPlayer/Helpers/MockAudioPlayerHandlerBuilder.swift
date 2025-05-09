@testable import MEGA

struct MockAudioPlayerHandlerBuilder: AudioPlayerHandlerBuilderProtocol {
    private let handler: any AudioPlayerHandlerProtocol
    
    init(handler: some AudioPlayerHandlerProtocol = MockAudioPlayerHandler()) {
        self.handler = handler
    }

    func build() -> any AudioPlayerHandlerProtocol {
        handler
    }
}
