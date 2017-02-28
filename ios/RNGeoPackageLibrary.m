
#import "RNGeoPackageLibrary.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@implementation RNGeoPackageLibrary

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(LibrarySampleCall:(NSString *)testString callback:(RCTResponseSenderBlock)callback) {
    callback(@[testString]);
}

RCT_EXPORT_METHOD(initGeoPackageatPath:(NSString *)path  forFileName:(NSString*)filename callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]initGeoPackageatPath:path forFileName:filename];
    callback(@[@""]);
}
//createFeatureclass (featureDict, geomentry)
RCT_EXPORT_METHOD(createFeatureclass:(NSDictionary *)featureDict  forGeomentryType:(int)geomentry callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]createFeatureclass:featureDict forGeomentry:geomentry];
    callback(@[@""]);
}
//insertFeatureclassRecord:(featureRecordDict, geomentry)
RCT_EXPORT_METHOD(insertFeatureclassRecord:(NSDictionary *)featurerecordDict  forGeomentryType:(int)geomentry callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]insertFeatureclassRecord:featurerecordDict forGeomentry:geomentry];
    callback(@[@""]);
}

RCT_EXPORT_METHOD(closeGeoPackage:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]closeGeoPackage];
    callback(@[@""]);
}

//import details
RCT_EXPORT_METHOD(getgpkgFileDetails:(NSString *)path callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]setEvent:self.bridge];
    NSMutableDictionary*dict = [[GeoPackageSingleton getSharedInstanceValue]getgpkgFileDetails:path];
     callback(@[dict]);
}

RCT_EXPORT_METHOD(importGeoPackage:(NSMutableDictionary *)gpkgArguments callback:(RCTResponseSenderBlock)callback) {
    [[GeoPackageSingleton getSharedInstanceValue]importGeoPackage:gpkgArguments];
     callback(@[@""]);
}


@end

