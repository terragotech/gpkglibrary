//
//  GeoPackageSingleton.m
//  RNGeoPackageLibrary
//
//  Created by Sunilkarthick Sivabalan on 18/02/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "GeoPackageSingleton.h"

//#import "RCTBridge.h"
// #import "RCTEventDispatcher.h"


static GeoPackageSingleton *sharedsingletonGeoPackageValue = nil;
@implementation GeoPackageSingleton
//@synthesize bridge = _bridge;

+(GeoPackageSingleton*)getSharedInstanceValue{
    if (!sharedsingletonGeoPackageValue) {
        sharedsingletonGeoPackageValue = [[super allocWithZone:NULL]init];
        sharedsingletonGeoPackageValue.geoPdf = [[GeoPDFAttachment alloc]init];
        sharedsingletonGeoPackageValue.gpkgFiles = [[NSMutableArray alloc]init];
    }
    return sharedsingletonGeoPackageValue;
}

-(void)initGeoPackageatPath:(NSString*)path forFileName:(NSString*)filename{
    NSError *error;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    self.filePath = path;
    //    NSString * file = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",filename]];
    NSString* folderPath = [[NSString alloc]initWithFormat:@"%@",path ];
    if (![fileManager fileExistsAtPath:folderPath])
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    NSString* resourcePath =[NSString stringWithFormat:@"%@/resources",folderPath];
    if (![fileManager fileExistsAtPath:resourcePath])
        [fileManager createDirectoryAtPath:resourcePath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    NSString *file = [NSString stringWithFormat:@"%@/%@.gpkg",folderPath,filename];
    
    manager = [GPKGGeoPackageFactory getManager];
    //    [manager open:[NSString stringWithFormat:@"%@/%@.gpkg",exportPath,fileName]];
    [manager deleteAll];
    //    [manager create:fileName];
    [manager close];
    manager = [GPKGGeoPackageFactory getManager];
    self.columnsTypesArray = [[NSMutableArray alloc]init];
    [manager create:filename];
    NSArray * databases = [manager databases];
    geoPackage = [manager open:[databases objectAtIndex:0]];
    //    [geoPackage setPath:path];
    //    [geoPackage setName:filename];
    [manager close];
    [geoPackage createGeometryColumnsTable];
    
    srsDao = [geoPackage getSpatialReferenceSystemDao];
    epsgSrs = (GPKGSpatialReferenceSystem *)[srsDao queryForIdObject:[NSNumber numberWithInt:4326]];
    geometryColumnsDao = [geoPackage getGeometryColumnsDao];
    contentsDao = [geoPackage getContentsDao];
    
    if (!self.featureClasses) {
        self.featureClasses = [[NSMutableArray alloc]init];
    }
    
    [self.featureClasses removeAllObjects];
}

-(int)createFeatureclass:(NSMutableDictionary*)featureDict forGeomentry:(int)geomentry{
    int ret = -1;
    
    NSString *featureName = [featureDict objectForKey:@"FeatureName"];
    NSMutableArray *featureColumns = [featureDict objectForKey:@"Columns"];
    GPKGContents * point2dContents = [[GPKGContents alloc] init];
    [point2dContents setTableName:featureName];
    [point2dContents setContentsDataType:GPKG_CDT_FEATURES];
    [point2dContents setIdentifier:featureName];
    //                [point2dContents set:@""];
    [point2dContents setLastChange:[NSDate date]];
    [point2dContents setMinX:[[NSDecimalNumber alloc] initWithDouble:-180.0]];
    [point2dContents setMinY:[[NSDecimalNumber alloc] initWithDouble:-90.0]];
    [point2dContents setMaxX:[[NSDecimalNumber alloc] initWithDouble:180.0]];
    [point2dContents setMaxY:[[NSDecimalNumber alloc] initWithDouble:90.0]];
    [point2dContents setSrs:epsgSrs];
    
    [self.columnsTypesArray removeAllObjects];
    
    enum WKBGeometryType geoColumnType = WKB_POINT;
    if (geomentry == 2) {
        geoColumnType = WKB_LINESTRING;
    }
    if (geomentry == 3) {
        geoColumnType = WKB_POLYGON;
    }
    NSMutableArray *columns = [[NSMutableArray alloc]init];
    [GPKGUtils addObject:[GPKGFeatureColumn createPrimaryKeyColumnWithIndex:0 andName:@"f_id"] toArray:columns];
    [GPKGUtils addObject:[GPKGFeatureColumn createGeometryColumnWithIndex:1 andName:@"geom" andGeometryType:geoColumnType andNotNull:false andDefaultValue:nil]toArray:columns];
    
    int i =2;
    for (NSDictionary *tdict in featureColumns) {
        GeoPackageColumn *gpc = [[GeoPackageColumn alloc]init];
        [gpc setFormelementID:[[tdict objectForKey:@"columnID"]intValue]];
        [gpc setColumnName:[tdict objectForKey:@"columnName"]];
        [gpc setColumnComponent:[tdict objectForKey:@"columnType"]];
        [self.columnsTypesArray addObject:gpc];
        [GPKGUtils addObject:[GPKGFeatureColumn createColumnWithIndex:i andName:[gpc columnName] andDataType:GPKG_DT_TEXT andNotNull:false andDefaultValue:nil]toArray:columns];
        i++;
    }
    
    GPKGFeatureTable *featureTable = [[GPKGFeatureTable alloc]initWithTable:featureName andColumns:columns];
    [geoPackage createFeatureTable:featureTable];
    
    [contentsDao create:point2dContents];
    
    GPKGGeometryColumns * point2dGeometryColumns = [[GPKGGeometryColumns alloc] init];
    [point2dGeometryColumns setContents:point2dContents];
    [point2dGeometryColumns setColumnName:@"geom"];
    [point2dGeometryColumns setGeometryType:geoColumnType];
    [point2dGeometryColumns setSrsId: point2dContents.srsId];
    [point2dGeometryColumns setZ:[NSNumber numberWithInt:0]];
    [point2dGeometryColumns setM:[NSNumber numberWithInt:0]];
    [geometryColumnsDao create:point2dGeometryColumns];
    
    ret = (int)[self.featureClasses count];
    [self.featureClasses addObject:featureTable];
    
    return ret;
}

-(void)insertFeatureclassRecord:(NSMutableDictionary*)featureRecordDict forGeomentry:(int)geomentry{
    
    NSString *featureName = [featureRecordDict objectForKey:@"FeatureName"];
    GPKGFeatureDao *featureDAO = [geoPackage getFeatureDaoWithTableName:featureName];
    
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDAO.projection];
    NSNumber * srsId = featureDAO.geometryColumns.srsId;
    
    GPKGFeatureRow * newLine;// = [featureDAO newRow];
    GPKGGeometryData * GeomData;
    NSString* geojson = [featureRecordDict objectForKey:@"Location"];
    
    NSMutableArray *pointsArray = [[NSMutableArray alloc]init];
    if (geomentry == 2) {
        for (CLLocation *loc in [self getCoordinatesFromGeoJson:geojson]) {
            [pointsArray addObject:[[GPKGMapPoint alloc]initWithLocation:[loc coordinate]]];
        }
        WKBLineString *line = [converter toLineStringWithMapPoints:pointsArray];
        GeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [GeomData setGeometry:line];
    }
    if (geomentry == 3) {
        for (CLLocation *loc in [self getCoordinatesFromGeoJson:geojson]) {
            [pointsArray addObject:[[GPKGMapPoint alloc]initWithLocation:[loc coordinate]]];
        }
        WKBPolygon *polygon = [converter toPolygonWithMapPoints:pointsArray andHolePoints:nil];
        GeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [GeomData setGeometry:polygon];
    }
    if (geomentry == 1) {
        GPKGMapPoint *pt;
        if ([[self getCoordinatesFromGeoJson:geojson]count]>=1) {
            CLLocationCoordinate2D cd = [(CLLocation*)[[self getCoordinatesFromGeoJson:geojson]objectAtIndex:0]coordinate];
            pt = [[GPKGMapPoint alloc]initWithLocation:cd];
        }
        WKBPoint * point = [converter toPointWithMapPoint:pt];
        GeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
        [GeomData setGeometry:point];
    }
    
    newLine = [featureDAO newRow];
    [newLine setGeometry:GeomData];
    NSMutableArray *valuesArray = [featureRecordDict objectForKey:@"values"];
    for (NSDictionary *tdict in valuesArray) {
        if ([[tdict objectForKey:@"columnName"]isEqualToString:@"fid"]) {
            continue;
        }
        [newLine setValueWithColumnName:[tdict objectForKey:@"columnName"] andValue:[tdict objectForKey:@"columnValue"]];
    }
    [featureDAO insert:newLine];
    
}

-(void)closeGeoPackage{
    [[NSFileManager defaultManager]moveItemAtPath:[geoPackage path] toPath:[NSString stringWithFormat:@"%@/%@",self.filePath,[[geoPackage path]lastPathComponent]] error:nil];
    [geoPackage close];
    [manager close];
}

-(NSMutableArray*)getCoordinatesFromGeoJson:(NSString*)geojson {
    NSMutableArray* coordinates = [[NSMutableArray alloc]init];
    @try {
        
        if ( !geojson || [geojson isEqualToString:@""] ) {
            return coordinates;
        }
        //     NSString * newString = [geometryVal stringByReplacingOccurrencesOfString:@"\"\"" withString:@"\""];
        //        NSString* geometry = geojson;
        
        
        NSMutableDictionary *json  = [NSJSONSerialization JSONObjectWithData:[geojson dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:0 error:NULL];
        
        NSMutableDictionary *geomentry = [json objectForKey:@"geometry"];
        
        
        //for polygon geojson
        if ([[geomentry objectForKey:@"type"]isEqualToString:@"Polygon"]) {
            NSMutableArray *points = [[geomentry valueForKeyPath:@"coordinates"]objectAtIndex:0];
            for (int i = 0; i < [points count]; i++) {
                NSArray *arr = [points objectAtIndex:i];
                CLLocation *lc = [[CLLocation alloc]initWithLatitude:[[arr objectAtIndex:1]doubleValue] longitude:[[arr objectAtIndex:0]doubleValue]];
                [coordinates addObject:lc];
            }
        }
        //for polyline geojson
        if ([[geomentry objectForKey:@"type"]isEqualToString:@"LineString"]) {
            NSMutableArray *points = [geomentry valueForKeyPath:@"coordinates"];
            for (int i = 0; i < [points count]; i++) {
                NSArray *arr = [points objectAtIndex:i];
                CLLocation *lc = [[CLLocation alloc]initWithLatitude:[[arr objectAtIndex:1]doubleValue] longitude:[[arr objectAtIndex:0]doubleValue]];
                [coordinates addObject:lc];
            }
        }
        
        //for point geojson
        if ([[geomentry objectForKey:@"type"]isEqualToString:@"Point"]) {
            NSMutableArray *points = [geomentry valueForKeyPath:@"coordinates"];
            if ([points count]==2) {
                CLLocation *lc = [[CLLocation alloc]initWithLatitude:[[points objectAtIndex:1]doubleValue] longitude:[[points objectAtIndex:0]doubleValue]];
                [coordinates addObject:lc];
            }
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally{
        return coordinates;
    }
}

#pragma mark import

-(void)initGeoPackageforPath:(NSString*)path{
    if(!self.georaster){
        self.georaster = [[GeoPackageRaster alloc]init];
    }
    BOOL isRaster = [self.georaster isRasterGeoPackage:path];
    if (isRaster) {
        NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
        [userDef setObject:@"GeoPackageRaster" forKey:@"packageType"];
        [userDef synchronize];
    }
    if (!import) {
        import = [[GeoPackageImport alloc]init];
    }
    [import initGeoPackageforpath:path];
}

-(BOOL)checkIsRasterforPath:(NSString*)path{
    if(!self.georaster){
        self.georaster = [[GeoPackageRaster alloc]init];
    }
    return [self.georaster isRasterGeoPackage:path];
}

-(NSMutableDictionary*)getgpkgFileDetails:(NSString*)path{
    [[self gpkgFiles]removeAllObjects];
    NSMutableDictionary *geoContent = [[NSMutableDictionary alloc]init];
    NSMutableArray *tgpkArray = [[NSMutableArray alloc]init];
    if ([[[path pathExtension]lowercaseString]isEqualToString:@"pdf"]) {
        NSArray *tempGpkgArray = [self.geoPdf getAllGeoPackagesforPDF:path];
        for (NSString *gpkgName in tempGpkgArray) {
            NSMutableDictionary *tGpkgDict = [[NSMutableDictionary alloc]init];
            [tGpkgDict setObject:gpkgName forKey:@"gpkgName"];
            NSString *tempPath = [self.geoPdf extractGeoPackagefromPDF:path forGeoPackage:gpkgName];
            NSMutableDictionary *fileDict = [[NSMutableDictionary alloc]init];
            [fileDict setObject:gpkgName forKey:@"Name"];
            [fileDict setObject:tempPath forKey:@"Path"];
            [[self gpkgFiles]addObject:fileDict];
            [self initGeoPackageforPath:tempPath];
            BOOL isRaster = [self checkIsRasterforPath:tempPath];
            [tGpkgDict setObject:[NSNumber numberWithBool:isRaster] forKey:@"isRaster"];
            NSArray *tempFeatureClasses = [import getAllFeatureClasses];
            NSMutableArray *featureArray = [[NSMutableArray alloc]init];
            for (NSString *feaName in tempFeatureClasses) {
                NSMutableDictionary *fetDict = [[NSMutableDictionary alloc]init];
                [fetDict setObject:feaName forKey:@"name"];
                [fetDict setObject:[self getGUID] forKey:@"guid"];
                [fetDict setObject:[import getAllAttributesforFeature:feaName] forKey:@"attributes"];
                [fetDict setObject:[NSNumber numberWithInt:[import notescountforFeature:feaName]] forKey:@"notesCount"];
                [featureArray addObject:fetDict];
            }
            [tGpkgDict setObject:featureArray forKey:@"featureClasses"];
            if (isRaster) {
                [tGpkgDict setObject:[self.georaster getTilesList] forKey:@"rasterLayers"];
            }
            [tgpkArray addObject:tGpkgDict];
        }
        
    }else{
        NSMutableDictionary *tGpkgDict = [[NSMutableDictionary alloc]init];
        [self initGeoPackageforPath:path];
        [tGpkgDict setObject:[[path lastPathComponent]stringByDeletingPathExtension] forKey:@"name"];
        BOOL isRaster = [self checkIsRasterforPath:path];
        [tGpkgDict setObject:[NSNumber numberWithBool:isRaster] forKey:@"isRaster"];
        NSArray *tempFeatureClasses = [import getAllFeatureClasses];
        NSMutableArray *featureArray = [[NSMutableArray alloc]init];
        for (NSString *feaName in tempFeatureClasses) {
            NSMutableDictionary *fetDict = [[NSMutableDictionary alloc]init];
            [fetDict setObject:feaName forKey:@"name"];
            [fetDict setObject:[self getGUID] forKey:@"guid"];
            [fetDict setObject:[import getAllAttributesforFeature:feaName] forKey:@"attributes"];
            [fetDict setObject:[NSNumber numberWithInt:[import notescountforFeature:feaName]] forKey:@"notesCount"];
            [featureArray addObject:fetDict];
        }
        [tGpkgDict setObject:featureArray forKey:@"featureClasses"];
        if (isRaster) {
            [tGpkgDict setObject:[self.georaster getTilesList] forKey:@"rasterLayers"];
        }
        [tgpkArray addObject:tGpkgDict];
    }
    [geoContent setObject:tgpkArray forKey:@"geopackages"];
    [self setImportGuid:[self getGUID]];
    [geoContent setObject:[self importGuid] forKey:@"importGuid"];
    self.isCancelled = FALSE;
    return geoContent;
}

-(void)importgeoPackageforFeatureClass:(NSString*)featureClass withDefaultNoteName:(NSString*)defaultName withFormGuid:(NSString*)formTemplateGuid{
    if([import isFormFeatureclass:featureClass]){
        NSMutableDictionary *frmtemp = [import createFormTemplateforFeatureClass:featureClass];
        
        NSMutableArray *geoNotes = [import importFeaturesforFeatureTemplate:frmtemp forFeatureClass:featureClass];
        int i = 0;
        for(int k=0; k<[geoNotes count];k++){
            NSMutableDictionary *note = [geoNotes objectAtIndex:k];
            [note setObject:defaultName forKey:@"title"];
            if (i>0) {
                [note setObject:[NSString stringWithFormat:@"%@_%d",defaultName,i] forKey:@"title"];
            }
            i++;
            // Side menu Cancel button pressed means
            // Need to work later for cancel
            //            if (self.isGeoPkgCancelled)
            //            {
            //                [self checkForUnSuccessfullImports];
            //                break;
            //            }
            [note setObject:[self importGuid] forKey:@"importGuid"];
            [note setObject:self.notebookGuid forKey:@"notebookGuid"];
            [note setObject:formTemplateGuid forKey:@"formTemplateGuid"];
            if (self.isCancelled) {
                return;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:note forKey:@"note"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noteImported" object:self userInfo:dict];
        }
    }
    else{
        NSMutableArray *geoNotes = [import importFeaturesforNonFormNotesFeatureClass:featureClass];
        for(int k=0; k<[geoNotes count];k++){
            NSMutableDictionary *note = [geoNotes objectAtIndex:k];
            // Side menu Cancel button pressed means
            //            if (self.isGeoPkgCancelled)
            //            {
            //                [self checkForUnSuccessfullImports];
            //                break;
            //            }
            [note setObject:[self importGuid] forKey:@"importGuid"];
            [note setObject:self.notebookGuid forKey:@"notebookGuid"];
            [note setObject:formTemplateGuid forKey:@"formTemplateGuid"];
            if (self.isCancelled) {
                return;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:note forKey:@"note"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noteImported" object:self userInfo:dict];
        }
    }
}


-(void)importgeoPackageforFeatureClass:(NSString*)featureClass withAttributeName:(NSString*)attributename withFormGuid:(NSString*)formTemplateGuid{
    if([import isFormFeatureclass:featureClass]){
        NSMutableDictionary *frmtemp = [import createFormTemplateforFeatureClass:featureClass];
        NSMutableArray *geoNotes = [import importFeaturesforFeatureTemplate:frmtemp forFeatureClass:featureClass withAttribute:attributename];
        for (NSMutableDictionary *note in geoNotes) {
            // Side menu Cancel button pressed means
            //            if (self.isGeoPkgCancelled)
            //            {
            //                [self checkForUnSuccessfullImports];
            //                break;
            //            }
            [note setObject:[self importGuid] forKey:@"importGuid"];
            [note setObject:self.notebookGuid forKey:@"notebookGuid"];
            [note setObject:formTemplateGuid forKey:@"formTemplateGuid"];
            if (self.isCancelled) {
                return;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:note forKey:@"note"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noteImported" object:self userInfo:dict];
        }
    }else{
        NSMutableArray *geoNotes = [import importFeaturesforNonFormNotesFeatureClass:featureClass];
        for (NSMutableDictionary *note in geoNotes) {
            // Side menu Cancel button pressed means
            //            if (self.isGeoPkgCancelled)
            //            {
            //                [self checkForUnSuccessfullImports];
            //                break;
            //            }
            [note setObject:[self importGuid] forKey:@"importGuid"];
            [note setObject:self.notebookGuid forKey:@"notebookGuid"];
            [note setObject:formTemplateGuid forKey:@"formTemplateGuid"];
            if (self.isCancelled) {
                return;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:note forKey:@"note"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noteImported" object:self userInfo:dict];
        }
    }
}

-(void)importRaster:(NSString*)tileName{
    NSString *frmPath = [[self georaster]convertMBTiles:tileName];
    NSMutableDictionary *raster = [[NSMutableDictionary alloc]init];
    [raster setObject:tileName forKey:@"rasterName"];
    [raster setObject:frmPath forKey:@"convertedPath"];
    [raster setObject:[self importGuid] forKey:@"importGuid"];
    [raster setObject:self.notebookGuid forKey:@"notebookGuid"];
    if(frmPath.length > 0)
    {
        if (self.isCancelled) {
            return;
        }
        //        NSDictionary *dict = [NSDictionary dictionaryWithObject:raster forKey:@"raster"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"rasterImported" object:self userInfo:raster];
    }
}

-(void)importGeoPackage:(NSMutableDictionary*)gpkgParameters{
    NSString *gpkgName = [gpkgParameters objectForKey:@"gpkgName"];
    self.notebookGuid = [gpkgParameters objectForKey:@"notebookGuid"];
    if (gpkgName) {
        NSString *gpkgPath=@"";
        for (NSDictionary* dict in [self gpkgFiles]) {
            if ([[dict objectForKey:@"Name"]isEqualToString:gpkgName]) {
                gpkgPath = [dict objectForKey:@"Path"];
                break;
            }
        }
        if (!import) {
            import = [[GeoPackageImport alloc]init];
        }else{
            [import closeGeoPackage];
        }
        [import initGeoPackageforpath:gpkgPath];
        NSArray *tFeatureArray = [gpkgParameters objectForKey:@"featureClasses"];
        for (NSDictionary *tFeatureDict in tFeatureArray) {
            if ([tFeatureDict objectForKey:@"defaultName"]) {
                [self importgeoPackageforFeatureClass:[tFeatureDict objectForKey:@"name"] withDefaultNoteName:[tFeatureDict objectForKey:@"defaultName"] withFormGuid:[tFeatureDict objectForKey:@"guid"]];
            }
            if ([tFeatureDict objectForKey:@"attributeName"]) {
                [self importgeoPackageforFeatureClass:[tFeatureDict objectForKey:@"name"] withAttributeName:[tFeatureDict objectForKey:@"attributeName"] withFormGuid:[tFeatureDict objectForKey:@"guid"]];
            }
        }
        NSArray *tRasterArray = [gpkgParameters objectForKey:@"rasterTiles"];
        for (NSString* tileName in tRasterArray) {
            [self importRaster:tileName];
        }
    }else{
        NSLog(@"%@",gpkgParameters);
        NSArray *tFeatureArray = [gpkgParameters objectForKey:@"featureClasses"];
        for (NSDictionary *tFeatureDict in tFeatureArray) {
            if ([tFeatureDict objectForKey:@"defaultName"]) {
                [self importgeoPackageforFeatureClass:[tFeatureDict objectForKey:@"name"] withDefaultNoteName:[tFeatureDict objectForKey:@"defaultName"] withFormGuid:[tFeatureDict objectForKey:@"guid"]];
            }
            if ([tFeatureDict objectForKey:@"attributeName"]) {
                [self importgeoPackageforFeatureClass:[tFeatureDict objectForKey:@"name"] withAttributeName:[tFeatureDict objectForKey:@"attributeName"] withFormGuid:[tFeatureDict objectForKey:@"guid"]];
            }
        }
        NSArray *tRasterArray = [gpkgParameters objectForKey:@"rasterTiles"];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                       {
        for (NSString* tileName in tRasterArray) {
            [self importRaster:tileName];
            NSDictionary* userInfo = @{@"Progress": @(0)};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RasterProgress" object:nil userInfo:userInfo];
        }
                       });
    }
}

-(NSString*)getGUID {
    NSUUID  *UUID = [NSUUID UUID];
    NSString* stringUUID = [UUID UUIDString];
    //
    return stringUUID;
}

-(void)processPDF:(NSString*)filePathPdf CreationPath:(NSString*)creationPath ProgressGuid:(NSString*)progressGuid DestinationPath:(NSString*)destinationPath{
    if(!self.georaster){
        self.georaster = [[GeoPackageRaster alloc]init];
    }
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                   {
                       [[self georaster] processPDF:filePathPdf CreationPath:creationPath ProgressGuid:progressGuid DestinationPath:destinationPath];
                   });
}

-(NSDictionary*)getSupportInfo:(NSString*)ptrInputFile {
    if(!self.georaster){
        self.georaster = [[GeoPackageRaster alloc]init];
    }
    return [[self georaster] getSupportInfo:ptrInputFile];
}

@end
