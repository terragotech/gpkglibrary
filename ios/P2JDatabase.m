//
//  P2JDatabase.m
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 24/10/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import "P2JDatabase.h"

static P2JDatabase *sharedP2JInstanceValue = nil;
static sqlite3 *gpkgdatabase = nil;

@implementation P2JDatabase

+(P2JDatabase*)getSharedInstanceValue{
    if (!sharedP2JInstanceValue) {
        sharedP2JInstanceValue = [[super allocWithZone:NULL]init];
//        [sharedP2JInstanceValue createDataBase];
    }
    return sharedP2JInstanceValue;
}

-(void)initDB:(NSString*)path{
//    NSString *docsDir = StoragePath;
    /**
     Build path to database file
     **/
    databasePathString = path;
    
    
    //  NSFileManager *filemgr = [NSFileManager defaultManager];
    //    if ([filemgr fileExistsAtPath: databasePathString ] == NO)
    //    {
    const char *dbpath = [databasePathString UTF8String];
    
    /****************** Check if database is null *******************/
    BOOL connected = FALSE;
    if(gpkgdatabase == NULL) {
        [self databaseSerialize];
        if (sqlite3_open(dbpath, &gpkgdatabase) == SQLITE_OK) {
            connected = TRUE;
        }
    }else {
        connected = TRUE;
    }
}

-(NSMutableArray*)getallPngDatafromTable:(NSString*)tablename{
    NSMutableArray *retVal = [[NSMutableArray alloc]init];
    const char *dbpathnew = [databasePathString UTF8String];
    /****************** Check if database is null *******************/
    BOOL connected = FALSE;
    
    if(gpkgdatabase == NULL) {
        [self databaseSerialize];
        if (sqlite3_open(dbpathnew, &gpkgdatabase) == SQLITE_OK) {
            connected = TRUE;
        }
    }else {
        connected = TRUE;
    }
    /****************** Check if database is null *******************/
    if (connected == TRUE){
        sqlite3_stmt *statement;
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT id, tile_data from %@",tablename];
        const char* sqlStatement = [selectSQL UTF8String];
        if( sqlite3_prepare_v2(gpkgdatabase, sqlStatement, -1, &statement, NULL) == SQLITE_OK ){
            while(sqlite3_step(statement) == SQLITE_ROW){
                P2JMetadata *metadata = [[P2JMetadata alloc]init];
                [metadata setIdVal:(int)sqlite3_column_int(statement, 0)];
                int len = sqlite3_column_bytes(statement, 1);
                [metadata setData:[[NSData alloc] initWithBytes: sqlite3_column_blob(statement, 1) length: len]];
                if ([self checkIsPng:[metadata data]]) {
                    [retVal addObject:metadata];
                }
            }
        }else{
             NSLog(@"Error while creating update statement:%s", sqlite3_errmsg(gpkgdatabase));
        }
    }
    return retVal;
}

-(BOOL)checkIsPng:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0x89:
            return true;
    }
    return false;
}

-(void)updateP2JforTable:(NSString*)table forMetadata:(P2JMetadata *)metaData
{
    UIImage *myImage = [UIImage imageWithData:[metaData data]];
    //NSData *pngData = UIImagePNGRepresentation(myImage);
    NSData *jpgData = UIImageJPEGRepresentation(myImage,80);
    
    sqlite3_stmt *updStmt =nil;
    int res = SQLITE_ERROR;
    //Update Tag SET NoteID = \"%d\",Tag = '%@' where NoteID =
    const char *sql = [[NSString stringWithFormat:@"Update %@ set  tile_data = ? where id = %d;",table,[metaData idVal]]UTF8String];
    res = sqlite3_prepare_v2(gpkgdatabase, sql, -1, &updStmt, NULL);
    
    if(res!= SQLITE_OK){
        NSLog(@"Error while creating update statement:%s", sqlite3_errmsg(gpkgdatabase));
    }
    
    res = sqlite3_bind_blob(updStmt, 1, [jpgData bytes], (int)[jpgData length] , SQLITE_TRANSIENT);
    
    if((res = sqlite3_step(updStmt)) != SQLITE_DONE)
    {
        NSLog(@"Error while updating: %s", sqlite3_errmsg(gpkgdatabase));
//        sqlite3_reset(updStmt);
    }
    
}

-(void)databaseSerialize {
    sqlite3_shutdown();
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    sqlite3_initialize();
}

-(void)closeDB{
    sharedP2JInstanceValue = nil;
    gpkgdatabase = nil;
    databasePathString = nil;
}


@end
