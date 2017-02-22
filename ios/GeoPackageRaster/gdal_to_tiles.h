#ifndef _GDAL_TO_TILES_H_
#define _GDAL_TO_TILES_H_
#define GN_BOOL_TRUE 1
#define GN_BOOL_FALSE 0
#define GN_VALUE_NONE 0

//Application Specific constants
#define MBGEN_LONG_STRING						1024

//Application Specific Error Codes
#define MBGEN_SUCCESS							0
#define MBGEN_BAD_INPUT_PARAMETERS				-2000
#define MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED	-2001

//GDAL Specific Error
#define MBGEN_ERROR_NO_RASTERS					-3000
#define MBGEN_ERROR_CANNOT_PROCESS_FILE			-3001
#define MBGEN_ERROR_PNG_CREATE_FAILED			-3002
#define MBGEN_ERROR_JPEG_CREATE_FAILED			-3003
#define MBGEN_ERROR_MEM_CREATE_FAILED			-3004
#define MBGEN_ERROR_WDS_CREATE_FAILED			-3005
#define MBGEN_ERROR_QRY_CREATE_FAILED			-3006
#define MBGEN_ERROR_MEM_DRV_LOAD_FAILED			-3007
#define MBGEN_ERROR_PNG_DRV_LOAD_FAILED			-3008			
#define MBGEN_ERROR_JPG_DRV_LOAD_FAILED			-3009


//File IO Specific errors
#define MBGEN_FILE_OPEN_FAILED					-4000			
#define MBGEN_FILE_IO_FAILED					-4001
#define MBGEN_FILE_BASE_TILES_NOT_FOUND			-4002
#define MBGEN_FILE_TILE_NOT_FOUND				-4003

//MBTiles Specific Error Codes
#define MBGEN_ERROR_INSERT_ROW_FAILED			-1000
#define MBGEN_ERROR_SQLITE_CLOSE_FAILED			-1001
#define MBGEN_ERROR_CREATE_TABLE_FAILED			-1002
#define MBGEN_ERROR_SQLITE_OPEN_FAILED			-1003
#define MBGEN_ERROR_BAD_TILE_IMAGE_FORMAT		-1004
#define MBGEN_ERROR_ZLEVEL						-1005
#define MBGEN_ERROR_QUALITY						-1006

#include "latlong.h"

#ifdef OS_WINDOWS_BUILD
#include <Windows.h>
#endif
#ifdef OS_UNIX_LINUX_BUILD
#include <sys/types.h>
#include <unistd.h>
#endif

//Linked List to hold the list of tiles from the Base tile

struct tile_exists_info
{
	int tx;
	int ty;
	int tz;
	struct tile_exists_info *next;
};


enum tile_format{
	png,
	jpg
};
struct TileInfo
{
	int tminx;
	int tminy;
	int tmaxx;
	int tmaxy;
};

struct xyzzy
{
	double querysize;
	int rx;
	int ry;
	int rxsize;
	int rysize;
	int wx;
	int wy;
	int wxsize;
	int wysize;
};

struct gdal_tiles{

	int tileSize;
	int scaledQuery;
	int querysize;
	int overviewquery;
	//resampling algo;
	tile_format fmt;
	int tminz;
	int tmaxz;

	int process_y;
	int process_x;

	int image_width;
	int image_height;

	int nimage_width;
	int nimage_height;

	GDALDatasetH  in_ds;
	GDALDatasetH  write_ds;
	GDALDatasetH  png_ds;
	GDALDatasetH  jpg_ds;

	GDALDriverH drvMEM;
	GDALDriverH drvPNG;
	GDALDriverH drvJPG;

	double ominx;
	double omaxx;
	double omaxy;
	double ominy;
	
	double in_gt[6];

	TileInfo tinfo[32];

	double south_lat;
	double west_lon;

	double north_lat;
	double east_lon;

	double center_lat;
	double center_lon;

	sqlite3 *db2;

	char *mbtiles_file_name;
	char *mbtiles_dir_name;
	char *mbtiles_format_type;

	char *input_filename;

	int bands;
	unsigned char *dataFromBand;

	GDALDataType pixelDataType;
	int bytes_per_pixel;

	struct tile_exists_info *ptrtile_info;

	int tile_found_count;

	int last_y_location;
	int last_x_location;

	int is_last_tile;

	int wx;
	int wy;
	int xsize;
	int ysize;

	int processing_stage;

	double top_left_corner_aspect_ratio_x;
	double top_right_corner_aspect_ratio_x;

	double bottom_left_corner_aspect_ratio_x;
	double bottom_right_corner_aspect_ratio_x;

	double left_aspect_ratio_x;
	double right_aspect_ratio_x;

	int png_modified;
	char *process_id;
	char *tmp_folder;

	int total_tile_count;
	int current_tile_count;
	int zoom_levels;

	char os_process_id[256];
	int next_xtile_exist;
	int next_ytile_exist;
	int corner_tile;
	double aspect_ratio;


	GDALDatasetH dstile;

	char image_type[6];		//png or jpeg
	char ZLEVEL[5];			//used with png	[1-9]
	char QUALITY[5];		//used with jpeg [10-100]
};
void clean_tmp_files_gtt(struct gdal_tiles *gt);
void remove_resources_gtt(struct gdal_tiles *gt);
void init_gdal_tiles_gtt(struct gdal_tiles *gt, char *pTMP);
int open_input_gtt(struct gdal_tiles *gt,struct global_mercator *gg);
void generate_metadata_gtt(struct gdal_tiles *gt,struct global_mercator *gg);
int generate_base_tiles_gtt(struct gdal_tiles *gt,struct global_mercator *gg);
int generate_overview_tiles_gtt(struct gdal_tiles *gt,struct global_mercator *gg);
void process(struct gdal_tiles *gt,struct global_mercator *gg);
int set_mbtiles_name_gtt(struct gdal_tiles *gt,char *mbtiles_file_name);
int set_input_filename_gtt(struct gdal_tiles *gt,char *filename);
int gn_max_gtt(int a,int b);
int open_mbtiles_gtt(struct gdal_tiles *gt);
int insert_metadata_mbtiles_gtt(struct gdal_tiles *gt);
int create_table_mbtiles_gtt(struct gdal_tiles *gt);
int close_mbtiles_gtt(struct gdal_tiles *gt);
double max_d_gtt(double a,double b);
double min_d_gtt(double a,double b);
int create_status_file_success(char *id);
int create_status_file_progress(char *id,double percentage);
int create_status_file_failed(char *id, char *reason);
int URLDecoder(char *ptrDst, char *ptrSrc);
int write_mbtiles_gtt(struct gdal_tiles *gtiles,int tz,int tx,int ty,unsigned char *ptrBlobData,unsigned int file_size);
int remove_existing_mbtiles_gtt(char *mbtile_file_name);
#endif