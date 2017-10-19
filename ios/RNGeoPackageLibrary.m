
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"RasterProgress"
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

RCT_EXPORT_METHOD(cancelImport:(NSString *)importID resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)  {
    [[GeoPackageSingleton getSharedInstanceValue]setIsCancelled:TRUE];
    resolve(@"");
}

RCT_EXPORT_METHOD(processGeoPDFMbtile:(NSString *)pdfFilePath mbtilePath:(NSString*)mbtilePath tempFolder:(NSString*)tempFolder progressGuid:(NSString*)progressGuid scratchPath:(NSString*)scratchPath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)  {
    NSDictionary* check = [[GeoPackageSingleton getSharedInstanceValue]getSupportInfo:pdfFilePath];
    if ([[check objectForKey:@"status"]isEqualToString:@"good"]) {
        NSString *tempPath = [NSString stringWithFormat:@"%@", [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0]];
        unsigned long long int totalFreeSpace = 0;
        NSError *error = nil;
        NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:tempPath error: &error];
        if (dictionary) {
            NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
            totalFreeSpace = ([freeFileSystemSizeInBytes unsignedLongLongValue]/1024)/1024;
        }
        unsigned long long int estimatedSpace = [[[[NSNumberFormatter alloc] init] numberFromString:[check objectForKey:@"estimate"]]unsignedLongLongValue];
        if (estimatedSpace < totalFreeSpace) {
             [[GeoPackageSingleton getSharedInstanceValue]processPDF:pdfFilePath CreationPath:tempFolder ProgressGuid:progressGuid DestinationPath:mbtilePath Scartchpath:scratchPath];
            resolve(@"trigger Progress");
        } else {
            resolve(@"Error: There is no free space to proceed");
        }
    } else {
        NSLog(@"Error in PDF2MBTile : %@",[check objectForKey:@"status"]);
        resolve( @"Error: Imported PDF is not valid PDF/No Georegistration found/Unsupported Projection/No Raster found");
    }
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
    if ([[notification name] isEqualToString:@"RasterProgress"]){
        NSDictionary* userInfo = notification.userInfo;
        [self.bridge.eventDispatcher sendAppEventWithName:@"rasterProgress" body:[NSString stringWithFormat:@"%@",[userInfo objectForKey:@"Progress"]]];
    }
}

@end

