
#import "SavedIdentifierParser.h"

@implementation SavedIdentifierParser

- (AssetIdentifierInfo *)parseSavedIdentifier:(NSString *)identifier separator:(NSString *)separator {
    AssetIdentifierInfo *info = [[AssetIdentifierInfo alloc] init];
    
    NSArray<NSString *> *separatedStrings = [identifier componentsSeparatedByString:separator];
    if (separatedStrings.count > 0) {
        if (separatedStrings.count == 1) {
            info.localIdentifier = [separatedStrings firstObject];
        } else if (separatedStrings.count == 2) {
            info.localIdentifier = [separatedStrings firstObject];
            info.mediaSubtype = (PHAssetMediaSubtype)[separatedStrings[1] integerValue];
        } else {
            NSString *subTypeString = [separatedStrings lastObject];
            info.mediaSubtype = (PHAssetMediaSubtype)[subTypeString integerValue];
            NSRange identifierRange = NSMakeRange(0, identifier.length - subTypeString.length - separator.length);
            info.localIdentifier = [identifier substringWithRange:identifierRange];
        }
    }
    
    return info;
}

@end
