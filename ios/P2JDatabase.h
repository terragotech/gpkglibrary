//
//  P2JDatabase.h
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 24/10/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <UIKit/UIKit.h>
#import "P2JMetadata.h"

@interface P2JDatabase : NSObject{
    NSString *databasePathString;
}

+(P2JDatabase*)getSharedInstanceValue;
-(void)initDB:(NSString*)path;
-(NSMutableArray*)getallPngDatafromTable:(NSString*)tablename;
-(void)updateP2JforTable:(NSString*)table forMetadata:(P2JMetadata *)metaData;
-(void)closeDB;

@end
