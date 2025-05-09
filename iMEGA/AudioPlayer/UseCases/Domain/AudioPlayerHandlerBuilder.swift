protocol AudioPlayerHandlerBuilderProtocol {
    func build() -> any AudioPlayerHandlerProtocol
}

struct AudioPlayerHandlerBuilder: AudioPlayerHandlerBuilderProtocol {
    func build() -> any AudioPlayerHandlerProtocol {
        AudioPlayerManager.shared
    }
}
