#ifndef GEOPACKAGE_RASTER_READER_H_

#include <stdio.h>
#include "ogrsf_frmts.h"
#include "ogr_p.h"
#include "gdalwarp_bin.h"
using namespace std;


//Success and Failure constants 
#define GEOPACKAGE_RASTER_READER_H_
#define GPKG_RASTER_READ_BAD_INPUT_PARAM -5000
#define GPKG_RASTER_READ_OPEN_FAILED  -5001
#define GPKG_RASTER_READ_NOT_OPENED  -5002
#define GPKG_RASTER_READ_TILE_NOT_FOUND  -5003
#define GPKG_RASTER_READ_SUBDATASET_OPEN_FAILED  -5004
#define GPKG_RASTER_READ_NOT_IN_PROGRESS  -5005
#define GPKG_RASTER_READ_SUCCESS  0
#define GPKG_RASTER_READ_STATE_DEFAULT  1
#define GPKG_RASTER_READ_STATE_OPEN_SUCCESS  2
#define GPKG_RASTER_READ_STATE_BASE_TILE_GEN  3
#define GPKG_RASTER_READ_STATE_OVERLAY_TILE_GEN  4
#define GPKG_RASTER_READ_STATE_MBTILES_GEN_COMPLETE  5
#define GPKG_RASTER_READ_STATE_CONVERSTION_INIT  6
#define GPKG_RASTER_READ_STATE_CANCELLED  7

struct GeoPackageRasterReader{
	int nGeoPackageReaderState;
	string logFileObj;										//log file
	
	GDALDatasetH hDS;											//Holds the pointer to DataSet
	char *ptrJSONResult;	
	bool bLogEnabled;											//Holds the state of the log file generated

	string inputGPKGFileName;
	GDALDatasetH hDSBounds;
	string strLatLongBounds;
};
void initGeoPackageRasterReader(GeoPackageRasterReader *gr);
int convertToMBtiles(GeoPackageRasterReader *gr, char *ptrFileName,
                     char *ptrMBTileName,
                     char *ptrTableName, char *ptrTMP);
void setGDALDATASettings(GeoPackageRasterReader *gr, char *ptrGDALPATH);
int closeGeoPackage(GeoPackageRasterReader *gr);
int getGeoPackageRasterReaderState(GeoPackageRasterReader *gr);
double getGeoPackageToMBTileConversionStatus(GeoPackageRasterReader *gr);
int cancelGeoPackageToMBTilesConversion(GeoPackageRasterReader *gr);
int initiateGeoPackageToMBTilesConversion(GeoPackageRasterReader *gr,char *ptrTileName, 
	int zoomLevels,
	int zlevel,
	int quality,
	char *ptrImgFormat,
	char *ptrMBTilesName);
char* getGeoPackageRasterNameListAsJSON(GeoPackageRasterReader *gr);

int openGeoPackage(GeoPackageRasterReader *gr, char *ptrFileName, char *ptrGDALSetting);
void OpenTileSetForBounds(GeoPackageRasterReader *gr, char *tileName);
int getBounds(GeoPackageRasterReader *gr,double *pLat, double *pLong);
bool hasSubDataSets(GeoPackageRasterReader *gr);
bool isValidTileSourceName(GeoPackageRasterReader *gr, char *ptrSDSName);


#endif