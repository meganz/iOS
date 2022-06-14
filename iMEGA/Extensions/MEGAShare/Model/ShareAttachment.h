
#import <Foundation/Foundation.h>

#import "ShareAttachmentType.h"

@interface ShareAttachment : NSObject

@property (nonatomic) ShareAttachmentType type;
@property (nonatomic) NSString *name;
@property (nonatomic) id content;

+ (NSMutableArray<ShareAttachment *> *)attachmentsArray;
+ (void)addGIF:(NSData *)data fromItemProvider:(NSItemProvider *)itemProvider;
+ (void)addImage:(UIImage *)image fromItemProvider:(NSItemProvider *)itemProvider;
+ (void)addFileURL:(NSURL *)url;
+ (void)addURL:(NSURL *)url;
+ (void)addContact:(NSData *)vCardData;
+ (void)addPlainText:(NSString *)text;
+ (void)addFolderURL:(NSURL *)url;

@end
