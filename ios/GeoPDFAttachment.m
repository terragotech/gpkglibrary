//
//  GeoPDFAttachment.m
//  TerragoEdge
//
//  Created by Sunilkarthick Sivabalan on 11/03/16.
//  Copyright © 2016 KNetworks. All rights reserved.
//

#import "GeoPDFAttachment.h"

#define PDFStoragePath [NSString stringWithFormat:@"%@/Data", [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0]]

@implementation GeoPDFAttachment

-(id)init{
    self = [super init];
    return self;
}

-(BOOL)isPDFcontainsGeoPackage:(NSString*)filePath{
    BOOL retVal = FALSE;
    NSURL *url = [NSURL fileURLWithPath:filePath isDirectory:NO];
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(pdf);
    
    CGPDFDictionaryRef names = NULL;
    if (CGPDFDictionaryGetDictionary(catalog, "Names", &names)) {
        CGPDFDictionaryRef embFiles = NULL;
        if (CGPDFDictionaryGetDictionary(names, "EmbeddedFiles", &embFiles)) {
            // At this point you know this is a Package/Portfolio
            
            CGPDFArrayRef nameArray = NULL;
            CGPDFDictionaryGetArray(embFiles, "Names", &nameArray);
            
            // nameArray contains the inner documents
            // it brings the name and then a dictionary from where you can extract the pdf
            
            for (int i = 0; i < CGPDFArrayGetCount(nameArray); i+=2) {
                CGPDFStringRef name = NULL;
                CGPDFDictionaryRef dict = NULL;
                
                if (CGPDFArrayGetString(nameArray, i, &name) &&
                    CGPDFArrayGetDictionary(nameArray, i+1, &dict)) {
                    NSString *_name = [self convertPDFString:name];
                    
                    if (![_name containsString:@"gpkg"] && ![_name containsString:@"GPKG"]) {
                        continue;
                    }
                    retVal = TRUE;
                }
            }
        }
    }
    return retVal;
}

-(NSMutableArray*)getAllGeoPackagesforPDF:(NSString*)filePath{
    NSMutableArray *retVal = [[NSMutableArray alloc]init];
    NSURL *url = [NSURL fileURLWithPath:filePath isDirectory:NO];
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(pdf);
    
    CGPDFDictionaryRef names = NULL;
    if (CGPDFDictionaryGetDictionary(catalog, "Names", &names)) {
        CGPDFDictionaryRef embFiles = NULL;
        if (CGPDFDictionaryGetDictionary(names, "EmbeddedFiles", &embFiles)) {
            // At this point you know this is a Package/Portfolio
            
            CGPDFArrayRef nameArray = NULL;
            CGPDFDictionaryGetArray(embFiles, "Names", &nameArray);
            
            // nameArray contains the inner documents
            // it brings the name and then a dictionary from where you can extract the pdf
            
            for (int i = 0; i < CGPDFArrayGetCount(nameArray); i+=2) {
                CGPDFStringRef name = NULL;
                CGPDFDictionaryRef dict = NULL;
                
                if (CGPDFArrayGetString(nameArray, i, &name) &&
                    CGPDFArrayGetDictionary(nameArray, i+1, &dict)) {
                    NSString *_name = [self convertPDFString:name];
                    
                    if (![_name containsString:@"gpkg"] && ![_name containsString:@"GPKG"]) {
                        continue;
                    }
                    [retVal addObject:[[_name lastPathComponent]stringByDeletingPathExtension]];
                }
            }
        }
    }
    return retVal;
}

-(NSString*)extractGeoPackagefromPDF:(NSString*)pdfPath forGeoPackage:(NSString*)geoPackageName{
    NSString *retPath = @"";
    NSURL *url = [NSURL fileURLWithPath:pdfPath isDirectory:NO];
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(pdf);
    CGPDFDictionaryRef names = NULL;
    if (CGPDFDictionaryGetDictionary(catalog, "Names", &names)) {
        CGPDFDictionaryRef embFiles = NULL;
        if (CGPDFDictionaryGetDictionary(names, "EmbeddedFiles", &embFiles)) {
            // At this point you know this is a Package/Portfolio
            
            CGPDFArrayRef nameArray = NULL;
            CGPDFDictionaryGetArray(embFiles, "Names", &nameArray);
            
            // nameArray contains the inner documents
            // it brings the name and then a dictionary from where you can extract the pdf
            
            for (int i = 0; i < CGPDFArrayGetCount(nameArray); i+=2) {
                CGPDFStringRef name = NULL;
                CGPDFDictionaryRef dict = NULL;
                
                if (CGPDFArrayGetString(nameArray, i, &name) &&
                    CGPDFArrayGetDictionary(nameArray, i+1, &dict)) {
                    NSString *_name = [self convertPDFString:name];
                    
                    if (![_name containsString:@"gpkg"] && ![_name containsString:@"GPKG"]) {
                        continue;
                    }
                    if (![[[_name lastPathComponent]stringByDeletingPathExtension] isEqualToString:geoPackageName]) {
                        continue;
                    }
                    CGPDFDictionaryRef EF;
                    if (CGPDFDictionaryGetDictionary(dict, "EF", &EF)) {
                        CGPDFStreamRef F;
                        if (CGPDFDictionaryGetStream(EF, "F", &F)) {
                            CFDataRef data = CGPDFStreamCopyData(F, NULL);
                            NSData *myData = (__bridge NSData *)data;
                            NSError *error;
                            NSString *documentsDirectory = PDFStoragePath; // Get documents folder
                            NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/PDFAttachments"];
                            if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
                                [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
                            }
                            NSString *path = [NSString stringWithFormat:@"%@/%@",dataPath,_name];
                            [myData writeToFile:path options:NSDataWritingAtomic error:&error];
                            retPath = path;
                            CFRelease(data);
                        }
                    }
                }
            }
        }
    }
    return retPath;
}

- (NSString *)convertPDFString:(CGPDFStringRef)string {
    CFStringRef cfString = CGPDFStringCopyTextString(string);
    NSString *result = [[NSString alloc] initWithString:(__bridge NSString *)cfString];
    CFRelease(cfString);
    return result;
}

@end
