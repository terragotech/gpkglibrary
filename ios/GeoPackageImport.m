//
//  GeoPackageImport.m
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 07/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import "GeoPackageImport.h"

@implementation GeoPackageImport

-(void)initGeoPackageforpath:(NSString*)urlString{
    manager = [GPKGGeoPackageFactory getManager];
    NSString *dbName = [[urlString lastPathComponent]stringByDeletingPathExtension];
    imported = [manager importGeoPackageFromPath:urlString andOverride:TRUE];
    if (imported) {
        srcPath = [urlString stringByDeletingLastPathComponent];
        fileManager = [NSFileManager defaultManager];
        NSArray * databases = [manager databases];
        geoPackage = [manager open:[databases objectAtIndex:[self getIndexforDB:databases withName:dbName]]];
    }
}

-(void)closeGeoPackage{
    imported = FALSE;
    [geoPackage close];
    [manager close];
}

-(NSArray*)getAllFeatureClasses{
    NSArray *features;
    if (imported) {
        features = [geoPackage getFeatureTables];
    }
    return features;
}

-(NSArray*)getAllAttributesforFeature:(NSString*)featureName{
    NSMutableArray *attributes = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        for (NSString *attrib in [[featureDao getFeatureTable]columnNames]) {
            if ([attrib isEqualToString:[[[featureDao getFeatureTable]getGeometryColumn]name]]) {
                continue;
            }
            [attributes addObject:attrib];;
        }
    }
    return attributes;
}

-(int)notescountforFeature:(NSString*)featureName{
    int cnt = 0;
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        cnt = [featureResults count];
        [featureResults close];
    }
    return cnt;
}

-(NSMutableDictionary*)createFormTemplateforFeatureClass:(NSString*)featureName{
    if (imported) {
        NSMutableDictionary* formTemplateDict = [[NSMutableDictionary alloc]init];
        [formTemplateDict setObject:featureName forKey:@"name"];
        
        NSMutableArray *formEleArray = [[NSMutableArray alloc]init];
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        NSString *pkName = [[[featureDao getFeatureTable]getPkColumn]name];
        
        int index = 0;
        if ([[featureDao getFeatureTable]getPkColumn]) {
            NSMutableDictionary *tempColumn = [[NSMutableDictionary alloc]init];
            [tempColumn setObject:[NSNumber numberWithInt:index] forKey:@"id"];
            [tempColumn setObject:[[[featureDao getFeatureTable]getPkColumn]name] forKey:@"label"];
            [tempColumn setObject:@"numberInput" forKey:@"component"];
            [tempColumn setObject:[NSNumber numberWithInt:index] forKey:@"index"];
            index++;
            [formEleArray addObject:tempColumn];
        }
        for (GPKGFeatureColumn *clmn in [[featureDao getFeatureTable]columns]) {
            if ([clmn isGeometry] || [[clmn name]isEqualToString:pkName]) {
                continue;
            }
            if([[clmn name]isEqualToString:@"Pictures_of_Damage"]){
                NSLog(@"dfffff") ;
            }
            NSMutableDictionary *fe = [self formElementforDatatype:[clmn dataType]];
            if (!fe) {
                continue;
            }
            
            NSString *strCmnName = [clmn name];
            if ([strCmnName containsString:FormFeatureAudioColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureAudioColumn withString:@""];
                [fe setObject:@"audioupload" forKey:@"component"];
            }else if ([strCmnName containsString:FormFeatureVideoColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureVideoColumn withString:@""];
                [fe setObject:@"videoupload" forKey:@"component"];
            }else if ([strCmnName containsString:FormFeatureImageColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureImageColumn withString:@""];
                [fe setObject:@"imageupload" forKey:@"component"];
            }else if ([strCmnName containsString:FormFeatureSignatureColumn]) {
                strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureSignatureColumn withString:@""];
                [fe setObject:@"signature" forKey:@"component"];
            }
            [fe setObject:[NSNumber numberWithInt:index] forKey:@"id"];
            [fe setObject:[NSNumber numberWithInt:index] forKey:@"index"];
            [fe setObject:strCmnName forKey:@"label"];
            index++;
            [formEleArray addObject:fe];
            
        }
        [formTemplateDict setObject:formEleArray forKey:@"formComponents"];
        return formTemplateDict;
    }
    return nil;
}

-(NSMutableArray*)importFeaturesforFeatureTemplate:(NSMutableDictionary*)featureTemplate forFeatureClass:(NSString*)featureName{
    NSMutableArray *retArray = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                NSMutableArray *frmCaptArr = [[NSMutableArray alloc]init];
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                
                int index = 0;
                if ([featureRow getPkColumn]) {
                    NSMutableDictionary *fc = [[NSMutableDictionary alloc]init];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"id"];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"index"];
                    index++;
                    [fc setObject:[[featureRow getPkColumn]name] forKey:@"label"];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]];
                    }
                    [fc setObject:[NSString stringWithFormat:@"%@%@%@",[[featureRow getPkColumn]name],repeatableLabelDelimiter,val] forKey:@"value"];
                    [fc setObject:[NSNumber numberWithBool:false] forKey:@"isAttachment"];
                    [frmCaptArr addObject:fc];
                }
                for (GPKGFeatureColumn *featColm in [[featureRow table]columns]) {
                    if ([featColm isGeometry] || [[featColm name]isEqualToString:[[[featureDao getFeatureTable]getPkColumn]name]]) {
                        continue;
                    }
                    
                    if ([[featColm name]isEqualToString:@"SURVEY_DAT"]) {
                        
                    }
                    NSMutableDictionary *fc = [[NSMutableDictionary alloc]init];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"id"];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"index"];
                    [fc setObject:[[featureRow getPkColumn]name] forKey:@"label"];
                    [fc setObject:[NSNumber numberWithBool:false] forKey:@"isAttachment"];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featColm index]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featColm index]]];
                    }
                    if ([[[featureRow getPkColumn]name]containsString:@"PicturesofDamage"]) {
                        
                    }
                    NSString *strCmnName =  [featColm name];;
                    if ([strCmnName containsString:FormFeatureAudioColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureAudioColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:true] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureVideoColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureVideoColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:true] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureImageColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureImageColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:true] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureSignatureColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureSignatureColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:true] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }
                    [fc setObject:strCmnName forKey:@"label"];
                    if( [fc objectForKey:@"isAttachment"]){
                        [fc setObject:[NSString stringWithFormat:@"%@",val] forKey:@"value"];
                    }else{
                        [fc setObject:[NSString stringWithFormat:@"%@%@%@",strCmnName,repeatableLabelDelimiter,val] forKey:@"value"];
                    }
                    //                    [fc setObject:[NSString stringWithFormat:@"%@%@%@",strCmnName,repeatableLabelDelimiter,val] forKey:@"value"];
                    
                    [frmCaptArr addObject:fc];
                    index++;
                    
                }
                
                NSMutableDictionary *note = [[NSMutableDictionary alloc]init];
                for (NSString *cName in [featureRow getColumnNames]) {
                    @try{
                        if([featureRow getValueWithColumnName:cName]){
                            [note setObject:[featureRow getValueWithColumnName:cName] forKey:cName];
                        }
                    }@catch (NSException *exception) {
                        NSLog(@"%@", exception.reason);
                    }
                }
                [note setObject:@"forms" forKey:@"noteType"];
                NSMutableArray *coordi = [[NSMutableArray alloc]init];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                            CLLocation *loc = [[CLLocation alloc]initWithLatitude:cd.latitude longitude:cd.longitude];
                            [coordi addObject:loc];
                            [note setObject:@"Point" forKey:@"geoType"];
                            
                        }
                    }
                }
                if([[geometryData geometry]geometryType]==WKB_POLYGON){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolygon *polygon = (MKPolygon*)[shape shape];
                            int pointCount = (int)[polygon pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polygon getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setObject:@"Polygon" forKey:@"geoType"];
                        }
                    }
                }
                
                if([[geometryData geometry]geometryType]==WKB_LINESTRING){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolyline *polyLine = (MKPolyline*)[shape shape];
                            int pointCount = (int)[polyLine pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polyLine getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setObject:@"LineString" forKey:@"geoType"];
                        }
                    }
                }
                
                [note setObject:[self getGeometry:coordi forType:[note objectForKey:@"geoType"]] forKey:@"geometry"];
                [note setObject:frmCaptArr forKey:@"formValues"];
                [note setObject:featureTemplate forKey:@"edgeformTemplate"];
                [retArray addObject:note];
                
            }
        }@finally {
            [featureResults close];
            return retArray;
        }
    }
    return retArray;
}

-(void)copyResourceforFormNote:(NSString*)values{
    NSArray *tarr = [values componentsSeparatedByString:@","];
    for (NSString *path in tarr) {
        NSString *src = [NSString stringWithFormat:@"%@/resources/%@",srcPath,[path lastPathComponent]];
        if ([fileManager fileExistsAtPath:src] ) {
            NSError *error;
            NSString *dest = [NSString stringWithFormat:@"%@/%@",GPKGStoragePath,[path lastPathComponent]];
            //            [note setResourceRef:dest];
            [fileManager copyItemAtPath:src toPath:dest error:&error];
            
        }
    }
}

-(NSString*)getFeatureIDforFeatureClass:(NSString*)featureName{
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        return [[[featureDao getFeatureTable]getPkColumn]name];
    }
    return nil;
}

-(NSMutableArray*)importFeaturesforFeatureTemplate:(NSMutableDictionary*)featureTemplate forFeatureClass:(NSString*)featureName withAttribute:(NSString*)attributeName{
    NSMutableArray *retArray = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                NSMutableArray *frmCaptArr = [[NSMutableArray alloc]init];
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                NSString *noteTitle = @"";
                int index = 0;
                if ([featureRow getPkColumn]) {
                    NSMutableDictionary *fc = [[NSMutableDictionary alloc]init];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"id"];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"index"];
                    index++;
                    [fc setObject:[[featureRow getPkColumn]name] forKey:@"label"];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]];
                    }
                    if ([attributeName isEqualToString:[[featureRow getPkColumn]name]]) {
                        noteTitle = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featureRow getPkColumnIndex]]];
                    }
                    [fc setObject:[NSString stringWithFormat:@"%@%@%@",[[featureRow getPkColumn]name],repeatableLabelDelimiter,val] forKey:@"value"];
                    [fc setObject:[NSNumber numberWithBool:FALSE] forKey:@"isAttachment"];
                    [frmCaptArr addObject:fc];
                }
                for (GPKGFeatureColumn *featColm in [[featureRow table]columns]) {
                    if ([featColm isGeometry] || [[featColm name]isEqualToString:[[[featureDao getFeatureTable]getPkColumn]name]]) {
                        continue;
                    }
                    if ([[featColm name]isEqualToString:@"SURVEY_DAT"]) {
                        
                    }
                    NSMutableDictionary *fc = [[NSMutableDictionary alloc]init];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"id"];
                    [fc setObject:[NSNumber numberWithInt:index] forKey:@"index"];
                    [fc setObject:[featColm name] forKey:@"label"];
                    [fc setObject:[NSNumber numberWithBool:FALSE] forKey:@"isAttachment"];
                    NSString *val = @"";
                    if ([featureRow getDatabaseValueWithIndex:[featColm index]]) {
                        val = [NSString stringWithFormat:@"%@",[featureRow getDatabaseValueWithIndex:[featColm index]]];
                    }
                    if ([attributeName isEqualToString:[featColm name]]) {
                        if ([featureRow getDatabaseValueWithIndex:[featColm index]]) {
                            noteTitle = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
                        }
                        if (noteTitle.length==0) {
                            noteTitle = @"Forms";
                        }
                    }
                    NSString *strCmnName = [featColm name];
                    if([strCmnName isEqualToString:@"Pictures_of_Damage"]){
                        NSLog(@"dfffff") ;
                    }
                    if ([strCmnName containsString:FormFeatureAudioColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureAudioColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:TRUE] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureVideoColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureVideoColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:TRUE] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureImageColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureImageColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:TRUE] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }else if ([strCmnName containsString:FormFeatureSignatureColumn]) {
                        strCmnName = [strCmnName stringByReplacingOccurrencesOfString:FormFeatureSignatureColumn withString:@""];
                        [fc setObject:[NSNumber numberWithBool:TRUE] forKey:@"isAttachment"];
                        [self copyResourceforFormNote:val];
                    }
                    [fc setObject:strCmnName forKey:@"label"];
                    if( [fc objectForKey:@"isAttachment"]){
                        [fc setObject:[NSString stringWithFormat:@"%@",val] forKey:@"value"];
                    }else{
                        [fc setObject:[NSString stringWithFormat:@"%@%@%@",strCmnName,repeatableLabelDelimiter,val] forKey:@"value"];
                    }
                    [frmCaptArr addObject:fc];
                    index++;
                    
                }
                NSMutableDictionary *note = [[NSMutableDictionary alloc]init];
                for (NSString *cName in [featureRow getColumnNames]) {
                    @try{
                        if([featureRow getValueWithColumnName:cName]){
                            [note setObject:[featureRow getValueWithColumnName:cName] forKey:cName];
                        }
                    }@catch (NSException *exception) {
                        NSLog(@"%@", exception.reason);
                    }
                }
                [note setObject:@"forms" forKey:@"noteType"];
                [note setObject:noteTitle forKey:@"title"];
                NSMutableArray *coordi = [[NSMutableArray alloc]init];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                            CLLocation *loc = [[CLLocation alloc]initWithLatitude:cd.latitude longitude:cd.longitude];
                            [coordi addObject:loc];
                            [note setObject:@"Point" forKey:@"geoType"];
                        }
                    }
                }
                if([[geometryData geometry]geometryType]==WKB_POLYGON){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolygon *polygon = (MKPolygon*)[shape shape];
                            int pointCount = (int)[polygon pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polygon getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setObject:@"Polygon" forKey:@"geoType"];
                        }
                    }
                }
                
                if([[geometryData geometry]geometryType]==WKB_LINESTRING){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolyline *polyLine = (MKPolyline*)[shape shape];
                            int pointCount = (int)[polyLine pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polyLine getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setObject:@"LineString" forKey:@"geoType"];
                        }
                    }
                }
                
                [note setObject:[self getGeometry:coordi forType:[note objectForKey:@"geoType"]] forKey:@"geometry"];
                [note setObject:frmCaptArr forKey:@"formValues"];
                [note setObject:featureTemplate forKey:@"edgeformTemplate"];
                [retArray addObject:note];
                
            }
        }@finally {
            [featureResults close];
            return retArray;
        }
    }
    return retArray;
}

-(void)geoPackageImportforFeatureClass:(NSString*)featureName{
    
    if (imported) {
        
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                }
                if(geometryData != nil && !geometryData.empty){
                    WKBGeometry * geometry = geometryData.geometry;
                    if(geometry != nil){
                        GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                        CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                        
                    }
                }
            }
        }@finally {
            [featureResults close];
        }
    }
}

-(NSMutableDictionary*)formElementforDatatype:(int)datatype{
    NSMutableDictionary *fe = [[NSMutableDictionary alloc]init];
    switch (datatype) {
        case 0:
            [fe setObject:@"radio" forKey:@"component"];
            [fe setObject:[[NSMutableArray alloc]initWithObjects:@"Yes",@"No",nil] forKey:@"options"];
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
            [fe setObject:@"numberInput" forKey:@"component"];
            break;
        case 9:
            [fe setObject:@"textInput" forKey:@"component"];
            break;
        case 11:
            [fe setObject:@"textInput" forKey:@"component"];
            break;
        case 12:
            [fe setObject:@"textInput" forKey:@"component"];
            break;
        default:
            return nil;
            break;
    }
    
    return fe;
}

-(int)getIndexforDB:(NSArray*)arr withName:(NSString*)dbName{
    int ret = -1;
    for (NSString *str in arr) {
        ret++;
        if ([str isEqualToString:dbName]) {
            break;
        }
    }
    return ret;
}
-(BOOL)isFormFeatureclass:(NSString*)featureClassName{
    BOOL isRet = false;
    GPKGFeatureDao *featureDao = [geoPackage getFeatureDaoWithTableName:featureClassName];
    for (NSString *columnName in [featureDao columns]) {
        if ([columnName isEqualToString:FeatureColumnNoteType]) {
            
            GPKGResultSet * featureResults = [featureDao queryForAll];
            @try {
                while([featureResults moveToNext]){
                    GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                    NSString *noteType = (NSString*)[featureRow getDatabaseValueWithColumnName:FeatureColumnNoteType];
                    if ([noteType isEqualToString:@"form"] || [noteType isEqualToString:@"forms"]||[noteType isEqualToString:@"multi"]) {
                        isRet= TRUE;
                        break;
                    }
                }
            }@catch(NSException *exception){
                
            }@finally{
                [featureResults close];
                return isRet;
            }
            return isRet;
        }
    }
    return isRet;
}

-(NSMutableArray*)importFeaturesforNonFormNotesFeatureClass:(NSString*)featureName{
    NSMutableArray *retArray = [[NSMutableArray alloc]init];
    if (imported) {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureName];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        @try {
            while([featureResults moveToNext]){
                GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
                
                NSMutableDictionary *note = [[NSMutableDictionary alloc]init];
                for (NSString *cName in [featureRow getColumnNames]) {
                    @try{
                        if([featureRow getValueWithColumnName:cName]){
                            [note setObject:[featureRow getValueWithColumnName:cName] forKey:cName];
                        }
                    }@catch (NSException *exception) {
                        NSLog(@"%@", exception.reason);
                    }
                }
                [note setObject:@"forms" forKey:@"noteType"];
                NSMutableArray *coordi = [[NSMutableArray alloc]init];
                GPKGGeometryData * geometryData = [featureRow getGeometry];
                if([[geometryData geometry]geometryType]==WKB_POINT){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            CLLocationCoordinate2D cd =[(GPKGMapPoint*)[shape shape]coordinate];
                            CLLocation *loc = [[CLLocation alloc]initWithLatitude:cd.latitude longitude:cd.longitude];
                            [coordi addObject:loc];
                            [note setObject:@"Point" forKey:@"geoType"];
                        }
                    }
                }
                if([[geometryData geometry]geometryType]==WKB_POLYGON){
                    
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolygon *polygon = (MKPolygon*)[shape shape];
                            int pointCount = (int)[polygon pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polygon getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setObject:@"Polygon" forKey:@"geoType"];
                        }
                    }
                }
                
                if([[geometryData geometry]geometryType]==WKB_LINESTRING){
                    if(geometryData != nil && !geometryData.empty){
                        WKBGeometry * geometry = geometryData.geometry;
                        if(geometry != nil){
                            GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                            MKPolyline *polyLine = (MKPolyline*)[shape shape];
                            int pointCount = (int)[polyLine pointCount];
                            CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
                            [polyLine getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
                            for (int c=0; c < pointCount; c++)
                            {
                                CLLocation *loc = [[CLLocation alloc]initWithLatitude:routeCoordinates[c].latitude longitude:routeCoordinates[c].longitude];
                                [coordi addObject:loc];
                            }
                            [note setObject:@"LineString" forKey:@"geoType"];
                        }
                    }
                }
                [note setObject:[self getGeometry:coordi forType:[note objectForKey:@"geoType"]] forKey:@"geometry"];
                [note setObject:[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnTitle] ? (NSString*)[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnTitle] : @"" forKey:@"title"];
                [note setObject:[featureRow getDatabaseValueWithColumnName:FeatureColumnNoteType]?(NSString*)[featureRow getDatabaseValueWithColumnName:FeatureColumnNoteType]:@"" forKey:@"noteType"];
                
                if ([self checkIsResourceNote:note]) {
                    @try {
                        NSString *src = [NSString stringWithFormat:@"%@/resources/%@",srcPath,[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnResourcePath] ? [(NSString*)[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnResourcePath]lastPathComponent] : @""];
                        if ([fileManager fileExistsAtPath:src] ) {
                            NSError *error;
                            NSString *dest = [NSString stringWithFormat:@"%@/%@",GPKGStoragePath,[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnResourcePath] ? [(NSString*)[featureRow getDatabaseValueWithColumnName:NonFormFeatureColumnResourcePath]lastPathComponent] : @""];
                            [note setObject:dest forKey:@"resourcePath"];
                            [fileManager copyItemAtPath:src toPath:dest error:&error];
                        }
                    }@catch (NSException *exception) {
                        NSLog(@"%@", exception.reason);
                    }
                }
                [retArray addObject:note];
            }
        }@finally {
            [featureResults close];
            return retArray;
        }
    }
    return retArray;
}

-(BOOL)checkIsResourceNote:(NSMutableDictionary*)note{
    if ([[note objectForKey:@"noteType"]isEqualToString:@"none"]) {
        return FALSE;
    }
    return TRUE;
}

-(NSString*)getGeometry:(NSMutableArray*)coordinates forType:(NSString*)geoType{
    if ([coordinates count]==0) {
        return @"";
    }
    NSMutableDictionary *mainDict = [[NSMutableDictionary alloc]init];
    @try { // crashlytics -- added try-catch exception
        [mainDict setObject:@"Feature" forKey:@"type"];
        NSMutableDictionary *secDict = [[NSMutableDictionary alloc]init];
        [secDict setObject:geoType forKey:@"type"];
        NSMutableArray *arry1 = [[NSMutableArray alloc]init];
        NSMutableArray *arry2 = [[NSMutableArray alloc]init];
        
        //Polygon
        if ([geoType isEqualToString:@"Polygon"]) {
            arry2 = [[NSMutableArray alloc]init];
            for (int i = 0; i < [coordinates count]; i++) {
                NSMutableArray *arry3 = [[NSMutableArray alloc]init];
                CLLocation *lc = [coordinates objectAtIndex:i];
                [arry3 addObject:[NSNumber numberWithDouble:lc.coordinate.longitude]];
                [arry3 addObject:[NSNumber numberWithDouble:lc.coordinate.latitude]];
                [arry2 addObject:arry3];
            }
            [arry1 addObject:arry2];
        }
        //Polyline
        if ([geoType isEqualToString:@"LineString"]) {
            arry2 = [[NSMutableArray alloc]init];
            for (int i = 0; i < [coordinates count]; i++) {
                NSMutableArray *arry3 = [[NSMutableArray alloc]init];
                CLLocation *lc = [coordinates objectAtIndex:i];
                [arry3 addObject:[NSNumber numberWithDouble:lc.coordinate.longitude]];
                [arry3 addObject:[NSNumber numberWithDouble:lc.coordinate.latitude]];
                [arry2 addObject:arry3];
            }
            [arry1 addObject:arry2];
        }
        //Point
        if ([geoType isEqualToString:@"Point"]) {
            if ([coordinates count]>0) {
                CLLocation *lc = [coordinates objectAtIndex:0];
                [arry1 addObject:[NSNumber numberWithDouble:lc.coordinate.longitude]];
                [arry1 addObject:[NSNumber numberWithDouble:lc.coordinate.latitude]];
            }
        }
        if ([geoType isEqualToString:@"LineString"]) {
            [secDict setObject:arry2 forKey:@"coordinates"];
        }else{
            [secDict setObject:arry1 forKey:@"coordinates"];
        }
        
        [mainDict setObject:secDict forKey:@"geometry"];
        
        NSMutableDictionary *thirDict = [[NSMutableDictionary alloc]init];
        //        [thirDict setObject:locationDescription forKey:@"name"];
        if ([geoType isEqualToString:@"LineString"] || [geoType isEqualToString:@"Polygon"]) {
            if ([coordinates count]>1) {
                int count = (int)[coordinates count];
                CLLocation *lo = [coordinates lastObject];
                CLLocation *fc = [coordinates firstObject];
                if ([geoType isEqualToString:@"Polygon"] && [lo coordinate].latitude == [fc coordinate].latitude && [lo coordinate].longitude == [fc coordinate].longitude) {
                    count--;
                }
            }
        }
        [mainDict setObject:thirDict forKey:@"properties"];
    }
    @catch (NSException *exception) {
        
    }
    NSString *geometry=@"";
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mainDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        //        NSString * newString = [jsonString stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
        geometry = jsonString;
    }
    return geometry;
}
@end

