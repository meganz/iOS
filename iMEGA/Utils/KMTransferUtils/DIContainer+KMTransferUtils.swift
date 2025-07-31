import KMTransferUtils
import MEGAAppPresentation

extension DIContainer {
    static var kmTransferUtils: some KMTransferring {
        MEGAKMTransferUtils(
            config: KMTransferConfig(
                kmQueryConfigs: [
                    KMQueryConfig(
                        service: "MEGA",
                        account: "sessionV3"
                    ),
                    KMQueryConfig(
                        service: "MEGA",
                        account: "statsid"
                    )
                ]
            )
        )
    }
}
