#import "MEGAChatMessage.h"

@class MEGAChatRoom;

typedef NS_ENUM(NSInteger, MEGAChatMessageWarningDialog) {
    MEGAChatMessageWarningDialogDismiss,
    MEGAChatMessageWarningDialogNone,
    MEGAChatMessageWarningDialogInitial,
    MEGAChatMessageWarningDialogStandard,
    MEGAChatMessageWarningDialogConfirmation
};

NS_ASSUME_NONNULL_BEGIN

@interface MEGAChatMessage (MNZCategory)

@property (nonatomic) uint64_t chatId;
@property (copy, nonatomic, nullable) NSAttributedString *attributedText;
@property (nonatomic) MEGAChatMessageWarningDialog warningDialog;
@property (copy, nonatomic, nullable) NSURL *MEGALink;
@property (copy, nonatomic, nullable) MEGANode *node;
@property (copy, nonatomic, nullable) NSString *richString;
@property (copy, nonatomic, nullable) NSNumber *richNumber;
@property (copy, nonatomic, nullable) NSString *richTitle;
@property (nonatomic) uint64_t contactLinkUserHandle;
@property (readonly) NSString *senderId;

- (BOOL)containsMEGALink;

/// Returns the first MEGA file, folder, public chat, contact or collection link in `content`,
/// or nil when there is none. Backs -containsMEGALink; exposed so the fast path can be tested
/// without building a MEGAChatMessage.
+ (nullable NSURL *)mnz_firstMEGALinkInContent:(nullable NSString *)content
    NS_SWIFT_NAME(firstMEGALink(inContent:));
- (BOOL)shouldShowForwardAccessory;
- (NSString *)generateAttributedString:(BOOL)isMeeting;

@end

NS_ASSUME_NONNULL_END
