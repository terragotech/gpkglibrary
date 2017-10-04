//
//  GeoPackageRaster.m
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 19/10/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import "GeoPackageRaster.h"
#import "GeoPackageRasterReader.h"
#import "P2JDatabase.h"
#import <Foundation/Foundation.h>
#import "GPKGConstant.h"


@interface GeoPackageRaster(){
//private interface, can define private methods and properties here
    NSString *gpkgFilePath;
    NSString *rasterDataFilePath;
    char *cstrgpkgFilePath;
    char *cstrgpkgFilePath1;
    struct GeoPackageRasterReader gr;
    GDALDatasetH hDataset;
    BOOL isRasterPackage;
    NSMutableArray *tileNames;
    char *cstrGeoData;
    char *tempPath;
}
@end

@implementation GeoPackageRaster

-(BOOL)isRasterGeoPackage:(NSString*)gpkgPath{
    rasterDataFilePath = [NSString stringWithFormat:@"%@/GeoData",GPKGStoragePath];
    gpkgFilePath = gpkgPath;
    
   
    
    
    isRasterPackage = false;
    cstrgpkgFilePath = (char*)[gpkgFilePath UTF8String];
    cstrgpkgFilePath1 = (char*)[gpkgFilePath UTF8String];
    tempPath =(char*) [[NSString stringWithFormat:@"%@/Temps",GPKGStoragePath]UTF8String];
    
    cstrGeoData =(char*) [rasterDataFilePath UTF8String];
//    GDALClose(<#GDALDatasetH hDS#>)
    gr.logFileObj = "LogFile.log";
    hDataset = NULL;
    GDALAllRegister();
    hDataset = GDALOpenEx( cstrgpkgFilePath, GDAL_OF_READONLY | GDAL_OF_RASTER | GDAL_OF_VERBOSE_ERROR, NULL,  NULL, NULL );
    if(hDataset != NULL){
        int xsize = GDALGetRasterXSize(hDataset);
        NSLog(@"XSize = %d",xsize);
        int ysize = GDALGetRasterYSize(hDataset);
        NSLog(@"YSize = %d",ysize);

        initGeoPackageRasterReader(&gr);
        openGeoPackage(&gr,cstrgpkgFilePath1,cstrGeoData);
       
        NSString *tileJson  = [NSString stringWithUTF8String:getGeoPackageRasterNameListAsJSON(&gr)];
        NSData *data = [tileJson dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *tileSources = [json objectForKey:@"tile_sources"];
        tileNames = [[NSMutableArray alloc]init];
        for (NSDictionary *tDict in tileSources) {
            if ([tDict objectForKey:@"tilename"]) {
                isRasterPackage = true;
                [tileNames addObject:[[NSString alloc]initWithFormat:@"%@",[tDict objectForKey:@"tilename"]]];
            }
        }
        closeGeoPackage(&gr);
//        convertToMBtiles(&gr,cstr4,tt,tableName,tempPath);
//        closeGeoPackage(&gr);
    }else{
        NSLog(@"un-success");
    }
    return isRasterPackage;
}

-(NSMutableArray*)getTilesList{
    return tileNames;
}

-(void)closeRasterGeoPackage{
    closeGeoPackage(&gr);
    [tileNames removeAllObjects];
    isRasterPackage = false;
}

-(NSString*)convertMBTiles:(NSString*)tileName{
    
    //Jpeg Conversion
    [[P2JDatabase getSharedInstanceValue]closeDB];
    [[P2JDatabase getSharedInstanceValue]initDB:gpkgFilePath];
    NSArray *tempArray = [[P2JDatabase getSharedInstanceValue]getallPngDatafromTable:tileName];
    for (P2JMetadata *meta in tempArray) {
        [[P2JDatabase getSharedInstanceValue]updateP2JforTable:tileName forMetadata:meta];
    }
    [[P2JDatabase getSharedInstanceValue]closeDB];
    //Jpeg Conversion
    
    char *tableName = (char*)[tileName UTF8String];
    tempPath =(char*)[[NSString stringWithFormat:@"%@/Temps",GPKGStoragePath]UTF8String];
    char *mbTile = (char*)[[NSString stringWithFormat:@"%@/%@.mbtiles",rasterDataFilePath,tileName]UTF8String];
    GDALAllRegister();
    gr.logFileObj = "LogFile.log";
    hDataset = GDALOpenEx( cstrgpkgFilePath, GDAL_OF_READONLY | GDAL_OF_RASTER | GDAL_OF_VERBOSE_ERROR, NULL,  NULL, NULL );
    if(hDataset != NULL){
        int xsize = GDALGetRasterXSize(hDataset);
        NSLog(@"XSize = %d",xsize);
        int ysize = GDALGetRasterYSize(hDataset);
        NSLog(@"YSize = %d",ysize);

        initGeoPackageRasterReader(&gr);
        openGeoPackage(&gr,cstrgpkgFilePath1,cstrGeoData);

    
    convertToMBtiles(&gr,cstrgpkgFilePath1,mbTile,tableName,tempPath);
    }
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Temps/mbtiles",GPKGStoragePath] error:&error];
    return [NSString stringWithFormat:@"%@/%@.mbtiles",rasterDataFilePath,tileName];
}

-(BOOL)isRasterPackage{
    return isRasterPackage;
}
-(BOOL)isRaster{
    return isRasterPackage;
}

-(int)processPDF:(NSString*)filePathPdf CreationPath:(NSString*)creationPath ProgressGuid:(NSString*)progressGuid DestinationPath:(NSString*)destinationPath{
    NSError *err;
    NSString *tmpPath = [creationPath stringByAppendingString:@"/tmp"];
    if(![[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:&err]) {
        //Error Handler
        NSLog(@"Error creating folder");
    }
    if(![[NSFileManager defaultManager] createDirectoryAtPath:[tmpPath stringByAppendingString:@"/mbtiles"] withIntermediateDirectories:YES attributes:nil error:&err]) {
        //Error Handler
        NSLog(@"Error creating folder");
    }
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithInt:511] forKey:NSFilePosixPermissions];
    [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:tmpPath error:&err];
    [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[tmpPath stringByAppendingString:@"/mbtiles"] error:&err];
    NSString *scrathPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) objectAtIndex:0] stringByAppendingString:@"/scratch"];
    if(![[NSFileManager defaultManager] createDirectoryAtPath:scrathPath withIntermediateDirectories:YES attributes:nil error:&err]) {
        //Error Handler
        NSLog(@"Error creating folder");
    }
    //Generating GDAL_DATA path
    //    NSString *gdalPath = @"";//[creationPath stringByAppendingString:@"/data"];
    const char *ptrGdalPath =  [NSBundle mainBundle].bundlePath.UTF8String;
    const char *ptrFileName = [filePathPdf UTF8String];
    const char *ptrMBTileName = [destinationPath UTF8String];
    const char *ptrProgressID = [progressGuid UTF8String];
    const char *ptrTMP = [tmpPath UTF8String];
    const char *ptrScratchFolder = [scrathPath UTF8String];
    NSString* randomID = [NSString stringWithFormat:@"%d",arc4random() % 9000 + 1000];
    int nPDFResult = geopdf_generateMBTilesFromGeoPDF((char*)ptrScratchFolder,(char*)ptrFileName,(char*)ptrMBTileName,(char*)ptrGdalPath,(char*)ptrProgressID,(char*)ptrTMP, (char*)[randomID UTF8String]);
    NSLog(@"Error code [%d]",nPDFResult);
    [self removeAllTempFileswithPID:randomID inPath:[tmpPath stringByAppendingString:@"/mbtiles"]];
    return nPDFResult;
}

- (void)removeAllTempFileswithPID:(NSString*)pid inPath:(NSString*)path {
    NSFileManager  *manager = [NSFileManager defaultManager];
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:path error:nil];
    NSString *predicate = [NSString stringWithFormat:@"self BEGINSWITH '%@_'",pid];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:predicate];
    NSArray *pidTempFiles = [allFiles filteredArrayUsingPredicate:fltr];
    for (NSString *tempFile in pidTempFiles) {
        NSError *error = nil;
        [manager removeItemAtPath:[path stringByAppendingPathComponent:tempFile] error:&error];
    }
}

@end
