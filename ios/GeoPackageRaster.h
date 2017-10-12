//
//  GeoPackageRaster.h
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 19/10/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "convtif.h"

@interface GeoPackageRaster : NSObject

-(BOOL)isRasterGeoPackage:(NSString*)gpkgPath;
-(NSMutableArray*)getTilesList;
-(void)closeRasterGeoPackage;
-(NSString*)convertMBTiles:(NSString*)tileName;
-(BOOL)isRasterPackage;
-(BOOL)isRaster;

-(int)processPDF:(NSString*)filePathPdf CreationPath:(NSString*)creationPath ProgressGuid:(NSString*)progressGuid DestinationPath:(NSString*)destinationPath;
-(NSDictionary*)getSupportInfo:(NSString*)ptrInputFile;

@end
