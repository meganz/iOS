import Foundation

struct SDKAvatarClient {

    var loadUserAvatar: (
        _ handle: HandleEntity,
        _ destinationPathURL: URL,
        _ completion: @escaping (UIImage?) -> Void
    ) -> Void

    var avatarBackgroundColorHex: (_ handle: HandleEntity) -> String?
}

extension SDKAvatarClient {

    static var live: Self {
        let api: MEGASdk? = MEGASdkManager.sharedMEGASdk()

        return Self(
            loadUserAvatar: { [weak api] userHandle, cachingDestinationPathURL, completion in
                guard let userBase64Handle = MEGASdk.base64Handle(forUserHandle: userHandle) else {
                    completion(nil)
                    return
                }

                let delegate = MEGAGetThumbnailRequestDelegate { request in
                    if request.file.contains(userBase64Handle) {
                        completion(UIImage(contentsOfFile: request.file))
                    }
                }
                api?.getAvatarUser(
                    withEmailOrHandle: userBase64Handle,
                    destinationFilePath: cachingDestinationPathURL.path,
                    delegate: delegate
                )
            },

            avatarBackgroundColorHex: { userHandle in
                MEGASdk.avatarColor(forBase64UserHandle: MEGASdk.base64Handle(forUserHandle: userHandle))
            }
        )
    }
}
