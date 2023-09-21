#import "SearchOperation.h"

#import "Helper.h"

#import "MEGASdkManager.h"
#import "MEGANodeList+MNZCategory.h"

@interface SearchOperation ()

@property (strong, nonatomic) MEGANode *parentNode;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) MEGACancelToken *cancelToken;
@property (assign, nonatomic) MEGASortOrderType sortOrderType;
@property (assign, nonatomic) MEGANodeFormatType nodeFormatType;
@property (strong, nonatomic) MEGASdk *sdk;
@property (copy, nonatomic) void (^completion)(NSArray <MEGANode *> *nodesFound, BOOL isCancelled);

@end

@implementation SearchOperation

- (instancetype)initWithParentNode:(MEGANode *)parentNode text:(NSString *)text cancelToken:(MEGACancelToken *)cancelToken sdk:(MEGASdk *)sdk completion:(void (^)(NSArray  <MEGANode *> *_Nullable, BOOL))completion {
    return [self initWithParentNode:parentNode
                               text:text
                        cancelToken:cancelToken
                      sortOrderType:[Helper sortTypeFor:parentNode]
                     nodeFormatType:MEGANodeFormatTypeUnknown
                                sdk: sdk
                         completion:completion];
}

- (instancetype)initWithParentNode:(MEGANode *)parentNode
                              text:(nullable NSString *)text
                       cancelToken:(MEGACancelToken *)cancelToken
                     sortOrderType:(MEGASortOrderType)sortOrderType
                    nodeFormatType:(MEGANodeFormatType)nodeFormatType
                               sdk:(MEGASdk *)sdk
                        completion:(void (^)(NSArray<MEGANode *> * _Nullable, BOOL))completion {
    self = super.init;
    if (self) {
        _parentNode = parentNode;
        _text = text;
        _completion = completion;
        _cancelToken = cancelToken;
        _sortOrderType = sortOrderType;
        _nodeFormatType = nodeFormatType;
        _sdk = sdk;
    }
    return self;
}

- (void)start {
    if (self.isCancelled) {
        [self finishOperation];
        if (self.completion) {
            self.completion(nil, true);
        }
        return;
    }
    
    [self startExecuting];
    
#ifdef DEBUG
    MEGALogInfo(@"[Search] \"%@\" starts", self.text);
#else
    MEGALogInfo(@"[Search] starts");
#endif
    MEGANodeList *nodeListFound = [self.sdk nodeListSearchForNode:self.parentNode
                                                     searchString:self.text
                                                      cancelToken:self.cancelToken
                                                        recursive:YES
                                                        orderType:self.sortOrderType
                                                   nodeFormatType:self.nodeFormatType
                                                 folderTargetType:MEGAFolderTargetTypeAll];
#ifdef DEBUG
    MEGALogInfo(@"[Search] \"%@\" finishes", self.text);
#else
    MEGALogInfo(@"[Search] finishes");
#endif
    
    if (self.completion) {
        if (self.isCancelled) {
#ifdef DEBUG
            MEGALogInfo(@"[Search] \"%@\" canceled", self.text);
#else
            MEGALogInfo(@"[Search] canceled");
#endif
            self.completion(nil, true);
        } else {
            NSArray *nodesFound = nodeListFound.mnz_nodesArrayFromNodeList;
            MEGALogInfo(@"[Search] %ld nodes found and added to the array", (long) nodesFound.count);
            self.completion(nodesFound, false);
        }
    }
    
    [self finishOperation];
}

@end
