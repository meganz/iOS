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
                    ),
                    // PIN related
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "demoPasscode"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "demoPasscodeTimerStart"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "passcodeTimerDuration"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "passcodeIsSimple"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "passcodeType"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "allowUnlockWithTouchID"
                    )
                ]
            )
        )
    }
}
