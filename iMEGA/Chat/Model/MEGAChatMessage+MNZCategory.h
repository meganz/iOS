
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
@property (readonly) NSString *senderId;

- (BOOL)containsMEGALink;
- (BOOL)shouldShowForwardAccessory;
- (NSString *)generateAttributedString;

@end

NS_ASSUME_NONNULL_END
