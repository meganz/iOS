
#import "ShareAttachment.h"

#import <ContactsUI/ContactsUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ShareAttachment

static NSMutableArray<ShareAttachment *> *_attachmentsArray;

+ (NSMutableArray<ShareAttachment *> *)attachmentsArray {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _attachmentsArray = [[NSMutableArray<ShareAttachment *> alloc] init];
    });
    return _attachmentsArray;
}

+ (void)addImage:(UIImage *)image fromItemProvider:(NSItemProvider *)itemProvider {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    BOOL isPNG = [itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePNG];
    shareAttachment.type = isPNG ? ShareAttachmentTypePNG : ShareAttachmentTypeImage;
    shareAttachment.name = [ShareAttachment suggestedNameForItemProvider:itemProvider];
    shareAttachment.content = image;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

+ (void)addFileURL:(NSURL *)url {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    shareAttachment.type = ShareAttachmentTypeFile;
    shareAttachment.name = [ShareAttachment suggestedNameForFileURL:url];
    shareAttachment.content = url;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

+ (void)addURL:(NSURL *)url {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    shareAttachment.type = ShareAttachmentTypeURL;
    shareAttachment.name = url.absoluteString;
    shareAttachment.content = url;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

+ (void)addContact:(NSData *)vCardData {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    shareAttachment.type = ShareAttachmentTypeContact;
    shareAttachment.name = [ShareAttachment suggestedNameForContact:vCardData];
    shareAttachment.content = vCardData;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

#pragma mark - Naming

+ (NSString *)suggestedNameForItemProvider:(NSItemProvider *)itemProvider {
    NSString *suggestedName;
    
    if (@available(iOS 11.0, *)) {
        suggestedName = itemProvider.suggestedName;
    } else {
        NSString *name = [[NSUUID UUID] UUIDString];
        NSString *extension = [itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePNG] ? @"png" : @"jpg";
        suggestedName = [NSString stringWithFormat:@"%@.%@", name, extension];
    }
    
    return suggestedName;
}

+ (NSString *)suggestedNameForFileURL:(NSURL *)url {
    NSString *lastPathComponent;
    
    NSString *path = url.path;
    NSMutableArray<NSString *> *fileNameComponents = [[path.lastPathComponent componentsSeparatedByString:@"."] mutableCopy];
    if (fileNameComponents.count > 1) {
        NSString *extension = fileNameComponents.lastObject.lowercaseString;
        [fileNameComponents replaceObjectAtIndex:(fileNameComponents.count - 1) withObject:extension];
    }
    lastPathComponent = [fileNameComponents componentsJoinedByString:@"."];
    
    return lastPathComponent;
}

+ (NSString *)suggestedNameForContact:(NSData *)vCardData {
    NSString *suggestedName;
    
    NSArray *contacts = [CNContactVCardSerialization contactsWithData:vCardData error:nil];
    for (CNContact *contact in contacts) {
        suggestedName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
        if (suggestedName.length > 0) {
            break;
        } else {
            suggestedName = [[contact.emailAddresses objectAtIndex:0] value];
            if (suggestedName.length > 0) {
                break;
            }
        }
    }

    if (suggestedName.length == 0) {
        suggestedName = [[NSUUID UUID] UUIDString];
    }
    
    suggestedName = [suggestedName stringByAppendingString:@".vcf"];
    
    return suggestedName;
}

@end
