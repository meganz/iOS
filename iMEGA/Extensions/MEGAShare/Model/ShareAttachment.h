
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ShareAttachmentType) {
    ShareAttachmentTypePNG,
    ShareAttachmentTypeImage,
    ShareAttachmentTypeFile,
    ShareAttachmentTypeURL,
    ShareAttachmentTypeContact,
    ShareAttachmentTypePlainText
};

@interface ShareAttachment : NSObject

@property (nonatomic) ShareAttachmentType type;
@property (nonatomic) NSString *name;
@property (nonatomic) id content;

+ (NSMutableArray<ShareAttachment *> *)attachmentsArray;
+ (void)addImage:(UIImage *)image fromItemProvider:(NSItemProvider *)itemProvider;
+ (void)addFileURL:(NSURL *)url;
+ (void)addURL:(NSURL *)url;
+ (void)addContact:(NSData *)vCardData;
+ (void)addPlainText:(NSString *)text;

@end
