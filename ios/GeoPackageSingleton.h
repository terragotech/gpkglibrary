//
//  GeoPackageSingleton.h
//  RNGeoPackageLibrary
//
//  Created by Sunilkarthick Sivabalan on 18/02/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "geopackage-ios-Bridging-Header.h"
#import "GeoPackageColumn.h"
#import "GeoPackageRaster.h"
#import "GeoPackageImport.h"
#import "GeoPDFAttachment.h"
#import "GPKGConstant.h"

@interface GeoPackageSingleton : NSObject
{
    GPKGGeoPackageManager *manager;
    GPKGGeoPackage *geoPackage;
    GPKGDataColumnsDao *dataColumnsDao;
    GPKGSpatialReferenceSystemDao *srsDao;
    GPKGSpatialReferenceSystem *epsgSrs;
    GPKGGeometryColumnsDao *geometryColumnsDao;
    GPKGContentsDao *contentsDao;
    GPKGDataColumnConstraintsDao *constraintsDao;
    
    //import
    GeoPackageImport *import;
    
}

typedef enum Goetypes
{
    POINT = 1,
    LINESTRING = 2,
    POLYGON = 3
} GeomentryType;

@property(nonatomic, retain)NSMutableArray* columnsTypesArray;
@property(nonatomic, retain)NSMutableArray* featureClasses;
@property(nonatomic, retain)NSString* importGuid;
@property(nonatomic, retain)NSString* filePath;
@property(nonatomic, retain)NSString* notebookGuid;

// @property(nonatomic, weak)RCTBridge<RCTBridgeModule> event;


//Export
+(GeoPackageSingleton*)getSharedInstanceValue;
-(int)createFeatureclass:(NSMutableDictionary*)featureDict forGeomentry:(int)geomentry;
-(void)insertFeatureclassRecord:(NSMutableDictionary*)featureRecordDict forGeomentry:(int)geomentry;
-(void)initGeoPackageatPath:(NSString*)path forFileName:(NSString*)filename;
-(void)closeGeoPackage;

//Import
@property(nonatomic,retain)GeoPackageRaster *georaster;
@property(nonatomic,retain)GeoPDFAttachment *geoPdf;
@property(nonatomic, retain)NSMutableArray *gpkgFiles;
-(void)initGeoPackageforPath:(NSString*)path;
-(BOOL)checkIsRasterforPath:(NSString*)path;
-(NSMutableDictionary*)getgpkgFileDetails:(NSString*)path;
-(void)importGeoPackage:(NSMutableDictionary*)gpkgParameters;

@end
