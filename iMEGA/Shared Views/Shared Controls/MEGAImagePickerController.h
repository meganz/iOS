
@interface MEGAImagePickerController : UIImagePickerController

- (id)init NS_UNAVAILABLE;

- (instancetype)initToUploadWithParentNode:(MEGANode *)parentNode sourceType:(UIImagePickerControllerSourceType)sourceType;

- (instancetype)initToChangeAvatarWithSourceType:(UIImagePickerControllerSourceType)sourceType;

- (instancetype)initToShareThroughChatWithSourceType:(UIImagePickerControllerSourceType)sourceType filePathCompletion:(void (^)(NSString *filePath, UIImagePickerControllerSourceType sourceType, MEGANode *myChatFilesNode))pathCompletion;

@end
