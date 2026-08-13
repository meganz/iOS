import MEGADomain

/// The outcome of measuring a pending transfer against the device.
enum DeviceStorageVerdict: Equatable {
    case fits
    /// Carries the two figures the warning quotes, so a shortfall cannot be reported without them.
    case doesNotFit(requiredBytes: UInt64, availableBytes: UInt64)
}

protocol DeviceStorageChecking: Sendable {
    /// Measures a pending operation against the space the device has left.
    /// - Parameter bytes: How much the operation still has to write to disk. The caller owns this
    ///   figure, since only it knows what its own flow reuses instead of downloading again.
    /// - Returns: `.fits` when the free space cannot be read, so a check that could not run never
    ///   blocks a transfer that may well succeed.
    func verdict(forAdditionalBytes bytes: UInt64) async -> DeviceStorageVerdict
}

/// Answers the storage question a transfer has to settle before it starts, so a download the device
/// has no room for is caught up front instead of failing file by file half way through.
///
/// Deliberately decides nothing beyond the measurement: which screens opt into the pre-check, behind
/// which feature flag, and how a shortfall is put to the user all belong to the caller.
struct DeviceStorageChecker: DeviceStorageChecking {
    private let deviceStorageUseCase: any DeviceStorageUseCaseProtocol

    init(deviceStorageUseCase: some DeviceStorageUseCaseProtocol) {
        self.deviceStorageUseCase = deviceStorageUseCase
    }

    func verdict(forAdditionalBytes bytes: UInt64) async -> DeviceStorageVerdict {
        do {
            let requirement = try await deviceStorageUseCase.requirement(forAdditionalBytes: bytes)

            MEGALogDebug(
                "[DeviceStorage] Pre-check: needs \(requirement.requiredBytes) bytes, "
                + "device has \(requirement.availableBytes), fits: \(requirement.isSatisfied)"
            )
            guard !requirement.isSatisfied else { return .fits }

            return .doesNotFit(
                requiredBytes: requirement.requiredBytes,
                availableBytes: requirement.availableBytes
            )
        } catch {
            MEGALogError("[DeviceStorage] Skipped the storage pre-check: \(error)")
            return .fits
        }
    }
}
