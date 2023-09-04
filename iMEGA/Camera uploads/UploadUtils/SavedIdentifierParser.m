#import "SavedIdentifierParser.h"

static NSString * const MEGACameraUploadIdentifierSeparator = @",";

@implementation SavedIdentifierParser

- (NSString *)savedIdentifierForLocalIdentifier:(NSString *)identifier mediaSubtype:(PHAssetMediaSubtype)subtype {
    return [@[identifier, [@(subtype) stringValue]] componentsJoinedByString:MEGACameraUploadIdentifierSeparator];
}

- (AssetIdentifierInfo *)parseSavedIdentifier:(NSString *)identifier {
    AssetIdentifierInfo *info = [[AssetIdentifierInfo alloc] init];
    
    NSArray<NSString *> *separatedStrings = [identifier componentsSeparatedByString:MEGACameraUploadIdentifierSeparator];
    if (separatedStrings.count > 0) {
        if (separatedStrings.count == 1) {
            info.localIdentifier = [separatedStrings firstObject];
        } else if (separatedStrings.count == 2) {
            info.localIdentifier = [separatedStrings firstObject];
            info.mediaSubtype = (PHAssetMediaSubtype)[separatedStrings[1] integerValue];
        } else {
            NSString *subTypeString = [separatedStrings lastObject];
            info.mediaSubtype = (PHAssetMediaSubtype)[subTypeString integerValue];
            NSRange identifierRange = NSMakeRange(0, identifier.length - subTypeString.length - MEGACameraUploadIdentifierSeparator.length);
            info.localIdentifier = [identifier substringWithRange:identifierRange];
        }
    }
    
    return info;
}

@end
