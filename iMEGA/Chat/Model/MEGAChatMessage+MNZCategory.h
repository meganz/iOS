
#import "MEGAChatMessage.h"
#import "JSQMessageData.h"

@class MEGAChatRoom;

typedef NS_ENUM(NSInteger, MEGAChatMessageWarningDialog) {
    MEGAChatMessageWarningDialogDismiss,
    MEGAChatMessageWarningDialogNone,
    MEGAChatMessageWarningDialogInitial,
    MEGAChatMessageWarningDialogStandard,
    MEGAChatMessageWarningDialogConfirmation
};

@interface MEGAChatMessage (MNZCategory) <JSQMessageData>

@property (nonatomic) uint64_t chatId;
@property (copy, nonatomic) NSAttributedString *attributedText;
@property (nonatomic) MEGAChatMessageWarningDialog warningDialog;
@property (copy, nonatomic) NSURL *MEGALink;
@property (copy, nonatomic) MEGANode *node;
@property (copy, nonatomic) NSString *richString;
@property (copy, nonatomic) NSNumber *richNumber;
@property (copy, nonatomic) NSString *richTitle;

- (BOOL)containsMEGALink;
- (BOOL)shouldShowForwardAccessory;

@end
