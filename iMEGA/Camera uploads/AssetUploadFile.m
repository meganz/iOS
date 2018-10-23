//
//  AssetUploadFile.m
//  MEGA
//
//  Created by Simon Wang on 16/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import "AssetUploadFile.h"

@implementation AssetUploadFile

- (NSURL *)fileURL {
    return [self.directoryURL URLByAppendingPathComponent:self.fileName];
}

- (NSURL *)encryptedURL {
    return [self.fileURL URLByAppendingPathExtension:@"encrypted"];
}

- (NSURL *)uploadURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.uploadURLString, self.uploadURLStringSuffix]];
}

- (NSURL *)previewURL {
    return [self.fileURL URLByAppendingPathExtension:@"preview"];
}

- (NSURL *)thumbnailURL {
    return [self.fileURL URLByAppendingPathExtension:@"thumbnail"];
}

@end
