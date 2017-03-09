
#import "RNGeoPackageLibrary.h"

#if __has_include("RCTBridge.h")
#import "RCTEventDispatcher.h"
#else
#import <React/RCTEventDispatcher.h>
#endif

@implementation RNGeoPackageLibrary

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
-(id)init{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"noteImported"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"rasterImported"
                                               object:nil];
    return self;
}
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(LibrarySampleCall:(NSString *)testString resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)  {
    resolve(testString);
}

RCT_EXPORT_METHOD(initGeoPackageatPath:(NSString *)path  forFileName:(NSString*)filename resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [[GeoPackageSingleton getSharedInstanceValue]initGeoPackageatPath:path forFileName:filename];
    resolve(@"");
}
//createFeatureclass (featureDict, geomentry)
RCT_EXPORT_METHOD(createFeatureclass:(NSDictionary *)featureDict  forGeomentryType:(int)geomentry resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)  {
    [[GeoPackageSingleton getSharedInstanceValue]createFeatureclass:featureDict forGeomentry:geomentry];
    resolve(@"");
}
//insertFeatureclassRecord:(featureRecordDict, geomentry)
RCT_EXPORT_METHOD(insertFeatureclassRecord:(NSDictionary *)featurerecordDict  forGeomentryType:(int)geomentry resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)  {
    [[GeoPackageSingleton getSharedInstanceValue]insertFeatureclassRecord:featurerecordDict forGeomentry:geomentry];
    resolve(@"");
}

RCT_EXPORT_METHOD(closeGeoPackage:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)  {
    [[GeoPackageSingleton getSharedInstanceValue]closeGeoPackage];
    resolve(@"");
}

//import details
RCT_EXPORT_METHOD(getgpkgFileDetails:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)  {
    //    [[GeoPackageSingleton getSharedInstanceValue]setEvent:self.bridge];
    NSMutableDictionary*dict = [[GeoPackageSingleton getSharedInstanceValue]getgpkgFileDetails:path];
    resolve(dict);
}

RCT_EXPORT_METHOD(importGeoPackage:(NSDictionary *)gpkgArguments  resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    [[GeoPackageSingleton getSharedInstanceValue]importGeoPackage:gpkgArguments];
    resolve(@"");
}

-(void)receiveNotification:(NSNotification *)notification{
    if ([[notification name] isEqualToString:@"noteImported"]){
        NSDictionary* userInfo = notification.userInfo;
        [self.bridge.eventDispatcher sendAppEventWithName:@"noteImported" body:userInfo];
    }
    if ([[notification name] isEqualToString:@"rasterImported"]){
        NSDictionary* userInfo = notification.userInfo;
        [self.bridge.eventDispatcher sendAppEventWithName:@"rasterImported" body:userInfo];
    }
}

@end

