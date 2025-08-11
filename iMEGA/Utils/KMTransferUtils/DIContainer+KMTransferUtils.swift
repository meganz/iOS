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
                        account: "demoPasscode",
                        label: "demoServiceName"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "demoPasscodeTimerStart",
                        label: "demoServiceName"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "passcodeTimerDuration",
                        label: "demoServiceName"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "passcodeIsSimple",
                        label: "demoServiceName"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "passcodeType",
                        label: "demoServiceName"
                    ),
                    KMQueryConfig(
                        service: "demoServiceName",
                        account: "allowUnlockWithTouchID",
                        label: "demoServiceName"
                    )
                ]
            )
        )
    }
}
