
#import "ShareAttachment.h"

#import <ContactsUI/ContactsUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "MEGAShare-Swift.h"
#import "NSString+MNZCategory.h"

@implementation ShareAttachment

static NSMutableArray<ShareAttachment *> *_attachmentsArray;

+ (NSMutableArray<ShareAttachment *> *)attachmentsArray {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _attachmentsArray = [[NSMutableArray<ShareAttachment *> alloc] init];
    });
    return _attachmentsArray;
}

+ (void)addGIF:(NSData *)data fromItemProvider:(NSItemProvider *)itemProvider {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    shareAttachment.type = ShareAttachmentTypeGIF;
    shareAttachment.name = [ShareAttachment suggestedNameForGIFWithItemProvider:itemProvider];
    shareAttachment.content = data;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

+ (void)addImage:(UIImage *)image fromItemProvider:(NSItemProvider *)itemProvider {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    BOOL isPNG = [itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePNG];
    shareAttachment.type = isPNG ? ShareAttachmentTypePNG : ShareAttachmentTypeImage;
    shareAttachment.name = [ShareAttachment suggestedNameForImageWithItemProvider:itemProvider];
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

+ (void)addPlainText:(NSString *)text {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    shareAttachment.type = ShareAttachmentTypePlainText;
    shareAttachment.name = [ShareAttachment suggestedNameForPlainText];
    shareAttachment.content = text;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

+ (void)addFolderURL:(NSURL *)url {
    ShareAttachment *shareAttachment = [[ShareAttachment alloc] init];
    shareAttachment.type = ShareAttachmentTypeFolder;
    shareAttachment.name = [ShareAttachment suggestedNameForFileURL:url];
    shareAttachment.content = url;
    [[ShareAttachment attachmentsArray] addObject:shareAttachment];
}

#pragma mark - Naming

+ (NSString *)suggestedUniqueNameWithItemProvider:(NSItemProvider *)itemProvider {
    NSString *suggestedName = [ShareAttachment suggestedUniqueNameWithString:itemProvider.suggestedName];
    return suggestedName;
}

+ (NSString *)suggestedUniqueNameWithString:(NSString *)suggestedName {
    NSString *newName = suggestedName;
    for (ShareAttachment *attachment in [ShareAttachment attachmentsArray]) {
        if ([newName isEqualToString:attachment.name]) {
            newName = nil;
            break;
        }
    }
    
    return newName;
}

+ (NSString *)suggestedNameForGIFWithItemProvider:(NSItemProvider *)itemProvider {
    NSString *suggestedName = [ShareAttachment suggestedUniqueNameWithItemProvider:itemProvider];
    
    if (!suggestedName) {
        NSString *name = [NSUUID UUID].UUIDString;
        suggestedName = [NSString stringWithFormat:@"%@.gif", name];
    }
    
    return suggestedName;
}

+ (NSString *)suggestedNameForImageWithItemProvider:(NSItemProvider *)itemProvider {
    NSString *suggestedName = [ShareAttachment suggestedUniqueNameWithItemProvider:itemProvider];
    
    if (!suggestedName) {
        NSString *name = [NSUUID UUID].UUIDString;
        NSString *extension = [itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePNG] ? @"png" : @"jpg";
        suggestedName = [NSString stringWithFormat:@"%@.%@", name, extension];
    }
    
    return suggestedName;
}

+ (NSString *)suggestedNameForFileURL:(NSURL *)url {
    NSString *lastPathComponent = [FileExtensionOCWrapper fileNameWithLowercaseExtensionFrom:url.lastPathComponent];
    NSString *suggestedName = [ShareAttachment suggestedUniqueNameWithString:lastPathComponent];
    if (!suggestedName) {
        suggestedName = [NSString stringWithFormat:@"%@.%@", [NSUUID UUID].UUIDString, [FileExtensionOCWrapper lowercasedLastExtensionIn:lastPathComponent]];
    }
    
    return suggestedName;
}

+ (NSString *)suggestedNameForContact:(NSData *)vCardData {
    NSString *suggestedName;
    
    NSArray *contacts = [CNContactVCardSerialization contactsWithData:vCardData error:nil];
    for (CNContact *contact in contacts) {
        suggestedName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
        if (suggestedName.length > 0) {
            break;
        } else {
            suggestedName = [contact.emailAddresses.firstObject value];
            if (suggestedName.length > 0) {
                break;
            }
        }
    }
    
    suggestedName = [ShareAttachment suggestedUniqueNameWithString:[suggestedName stringByAppendingString:@".vcf"]];

    if (!suggestedName || suggestedName.length == 0) {
        suggestedName = [[NSUUID UUID].UUIDString stringByAppendingString:@".vcf"];
    }
    
    return suggestedName;
}

+ (NSString *)suggestedNameForPlainText {
    return [[NSUUID UUID].UUIDString stringByAppendingString:@".txt"];
}

@end
