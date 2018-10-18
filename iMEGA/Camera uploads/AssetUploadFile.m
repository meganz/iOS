//
//  AssetUploadFile.m
//  MEGA
//
//  Created by Simon Wang on 16/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import "AssetUploadFile.h"

@implementation AssetUploadFile

- (NSURL *)encryptedURL {
    return [self.fileURL URLByAppendingPathExtension:@"encrypted"];
}

- (NSURL *)uploadURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.uploadURLString, self.uploadURLStringSuffix]];
}

@end
