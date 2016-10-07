#import "MEGAChatSdk.h"
#import "megachatapi.h"
#import "MEGASdk+init.h"
#import "MEGAChatSdk+init.h"
#import "MEGAChatError+init.h"
#import "DelegateMEGAChatRequestListener.h"
#import "DelegateMEGAChatLoggerListener.h"

#import <set>
#import <pthread.h>

using namespace megachat;

@interface MEGAChatSdk () {
    pthread_mutex_t listenerMutex;
}

@property (nonatomic, assign) std::set<DelegateMEGAChatRequestListener *>activeRequestListeners;

- (MegaChatRequestListener *)createDelegateMEGAChatRequestListener:(id<MEGAChatRequestDelegate>)delegate singleListener:(BOOL)singleListener;

@property MegaChatApi *megaChatApi;
- (MegaChatApi *)getCPtr;

@end

@implementation MEGAChatSdk

static DelegateMEGAChatLogerListener *externalLogger = NULL;
#pragma mark - Init

- (instancetype)init:(MEGASdk *)megaSDK {
    
    if (!externalLogger)
    {
        externalLogger = new DelegateMEGAChatLogerListener(nil);
    }
    
    self.megaChatApi = new MegaChatApi((mega::MegaApi *)[megaSDK getCPtr]);
    
    if (pthread_mutex_init(&listenerMutex, NULL)) {
        return nil;
    }
    
    return self;
}

- (void)openSession:(BOOL)resumeSession delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->init(resumeSession, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)openSession:(BOOL)resumeSession {
    self.megaChatApi->init(resumeSession);
}

- (void)connectWithDelegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->connect([self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)connect {
    self.megaChatApi->connect();
}

- (void)dealloc {
    delete _megaChatApi;
    pthread_mutex_destroy(&listenerMutex);
}

- (MegaChatApi *)getCPtr {
    return _megaChatApi;
}

#pragma mark - Private methods

- (MegaChatRequestListener *)createDelegateMEGAChatRequestListener:(id<MEGAChatRequestDelegate>)delegate singleListener:(BOOL)singleListener {
    if (delegate == nil) return nil;
    
    DelegateMEGAChatRequestListener *delegateListener = new DelegateMEGAChatRequestListener(self, delegate, singleListener);
    pthread_mutex_lock(&listenerMutex);
    _activeRequestListeners.insert(delegateListener);
    pthread_mutex_unlock(&listenerMutex);
    return delegateListener;
}

- (void)freeRequestListener:(DelegateMEGAChatRequestListener *)delegate {
    if (delegate == nil) return;
    
    pthread_mutex_lock(&listenerMutex);
    _activeRequestListeners.erase(delegate);
    pthread_mutex_unlock(&listenerMutex);
    delete delegate;
}

@end
