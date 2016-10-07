#import <Foundation/Foundation.h>
#import "MEGAChatRequest.h"
#import "MEGAChatError.h"

@class MEGAChatSdk;

@protocol MEGAChatRequestDelegate <NSObject>

@optional

- (void)onChatRequestStart:(MEGAChatSdk *)api request:(MEGAChatRequest *)request;
- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error;
- (void)onChatRequestUpdate:(MEGAChatSdk *)api request:(MEGAChatRequest *)request;
- (void)onChatRequestTemporaryError:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error;

@end

