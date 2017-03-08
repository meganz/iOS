#import <Foundation/Foundation.h>
#import "JSQMessageData.h"
#import "MEGAChatMessage.h"
#import "MEGAChatRoom.h"

@interface MEGAMessage : NSObject <JSQMessageData>

NS_ASSUME_NONNULL_BEGIN
@property (copy, nonatomic, readonly) NSString *senderId;
@property (copy, nonatomic, readonly) NSString *senderDisplayName;
@property (copy, nonatomic, readonly) NSDate *date;
@property (assign, nonatomic, readonly) BOOL isMediaMessage;
@property (copy, nonatomic, null_unspecified) NSString *text;
@property (copy, nonatomic, readonly, null_unspecified) id<JSQMessageMediaData> media;

#pragma mark - Mega additions

@property (nonatomic, readonly) uint64_t messageId;
@property (nonatomic, readonly) uint64_t temporalId;
@property (nonatomic, readonly) uint64_t userHandle;
@property (nonatomic, readonly) NSInteger index;
@property (assign, nonatomic, readonly, getter=isEditable) BOOL editable;
@property (assign, nonatomic, readonly, getter=isEdited) BOOL edited;
@property (assign, nonatomic, readonly, getter=isDeleted) BOOL deleted;
@property (assign, nonatomic, readonly, getter=isManagementMessage) BOOL managementMessage;
@property (nonatomic, readonly) MEGAChatMessageType type;
@property (nonatomic, readonly) MEGAChatMessageStatus status;

@property (copy, nonatomic, null_unspecified) NSAttributedString *attributedText;

#pragma mark - Initialization

// Not a valid initializer.
- (id)init NS_UNAVAILABLE;
- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message megaChatRoom:(MEGAChatRoom *)chatRoom;

@end

NS_ASSUME_NONNULL_END
