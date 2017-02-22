//
//  GeoPackageRaster.m
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 19/10/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import "GeoPackageRaster.h"
#import "GeoPackageRasterReader.h"
#import "Constants.h"
#import "P2JDatabase.h"
#import <Foundation/Foundation.h>

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
    rasterDataFilePath = [NSString stringWithFormat:@"%@/GeoData",StoragePath];
    gpkgFilePath = gpkgPath;
    
   
    
    
    isRasterPackage = false;
    cstrgpkgFilePath = (char*)[gpkgFilePath UTF8String];
    cstrgpkgFilePath1 = (char*)[gpkgFilePath UTF8String];
    tempPath =(char*) [[NSString stringWithFormat:@"%@/Temps",StoragePath]UTF8String];
    
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
    tempPath =(char*)[[NSString stringWithFormat:@"%@/Temps",StoragePath]UTF8String];
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
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Temps/mbtiles",StoragePath] error:&error];
    return [NSString stringWithFormat:@"%@/%@.mbtiles",rasterDataFilePath,tileName];
}

-(BOOL)isRasterPackage{
    return isRasterPackage;
}
-(BOOL)isRaster{
    return isRasterPackage;
}
@end
