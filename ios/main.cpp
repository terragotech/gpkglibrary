#include "config.h"
#include "logger.h"
#include "utils.h"
#include "global_mercator.h"
#include "gdal_to_tiles.h"
#define ANDROID_BUILD
int convert_mbtiles(char *file_name,
				   char *mbtile_file_name,
				   char *zoom_levels,
				   char *image_type,
				   char *zlevel,
				   char *quality,
				   char *process_id,
					char *tmpPath, char *progfile)
{
	 
	struct gdal_tiles gt;
	struct global_mercator gm;
	
	
	if((file_name != NULL) || (mbtile_file_name != NULL) || (image_type != NULL) || (zlevel != NULL) || (quality != NULL) ){
		int func_result = 0;
		init_global_mercator(&gm);
		init_gdal_tiles_gtt(&gt,tmpPath);
#ifndef ANDROID_BUILD
		gt.process_id = (char*)malloc(strlen(process_id)+1);
		if(gt.process_id == NULL)
		{
			create_status_file_failed(process_id,"Memory allocation failed");
			exit(0);
		}
		strcpy(gt.process_id,process_id);
		string objLogFileName;
		objLogFileName.clear();
		objLogFileName.append(gt.process_id);
		objLogFileName.append("_mbtiles.log");

#else
		gt.process_id = (char*)malloc(strlen(progfile)+1);
		if(gt.process_id != NULL){
			strcpy(gt.process_id,progfile);
		}
		string objLogFileName;
        objLogFileName.clear();
        objLogFileName.append(gt.process_id);
        objLogFileName.append("_mbtiles.log");
#endif
//Set the tile format
if(!( ( strcmp(image_type,"jpeg") == 0 ) || ( strcmp(image_type,"png") == 0 )))
{
    printf("\nBad image type parameter");
    create_status_file_failed(gt.process_id,(char*)"Bad image type parameter");
    exit(0);
}
if(!((strlen(zlevel) == 1) && ((atoi(zlevel) >= 1 ) && (atoi(zlevel) <= 9))))
{
    printf("\nBad ZLEVEL parameter");
    create_status_file_failed(gt.process_id,(char*)"Bad zlevel parameter");
    exit(0);
}
if(!( ( (strlen(quality) > 1) || (strlen(quality) < 4) ) && ( (atoi(quality) >= 10 ) && ( atoi(quality) <= 100 ) ) ) )
{
    printf("\nBad Quality parameter");
    create_status_file_failed(gt.process_id,(char*)"Bad quality parameter");
    exit(0);
}
strcpy(gt.image_type,image_type);
strcpy(gt.ZLEVEL,zlevel);
strcpy(gt.QUALITY,quality);

write_log((char*)objLogFileName.c_str(),(char*)"INFO:Assiging input file name");
func_result = set_input_filename_gtt(&gt,file_name);
switch(func_result)
{
    case MBGEN_BAD_INPUT_PARAMETERS:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:conver_mbtiles,Bad Input parameters");
        create_status_file_failed(gt.process_id,(char*)"Bad Input parameters");
        exit(0);
    }
    break;
    case MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:conver_mbtiles,Memory allocation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"Insufficient Memory");
        exit(0);
    }
    break;
}
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Assiging input file name complete");
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Assiging MBTiles file name");
func_result = set_mbtiles_name_gtt(&gt,mbtile_file_name);
switch(func_result)
{
    case MBGEN_BAD_INPUT_PARAMETERS:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:conver_mbtiles,set_mbtiles_name_gtt, Bad Input parameters");
        create_status_file_failed(gt.process_id,(char*)"Bad Input parameters");
        exit(0);
    }
    break;
    case MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:conver_mbtiles,set_mbtiles_name_gtt,Memory allocation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"Insufficient Memory");
        exit(0);
    }
    break;
}
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Assiging MBTiles file name complete");
if(strlen(zoom_levels) != 0 ){
    gt.zoom_levels = atoi(zoom_levels);
}
else
{
    gt.zoom_levels = -1;
}

write_log((char*)objLogFileName.c_str(),(char*)"Start Processing");
func_result = open_input_gtt(&gt,&gm);
switch(func_result)
{
case MBGEN_ERROR_MEM_DRV_LOAD_FAILED:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, open_input_gtt, GDAL Memory driver [FAILED] to load");
        create_status_file_failed(gt.process_id,(char*)"Memory Driver failed");
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
case MBGEN_ERROR_PNG_DRV_LOAD_FAILED:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, open_input_gtt, GDAL PNG driver [FAILED] to load");
        create_status_file_failed(gt.process_id,(char*)"PNG Driver failed");
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
case MBGEN_ERROR_JPG_DRV_LOAD_FAILED:
{
    write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, open_input_gtt, GDAL JPEG driver [FAILED] to load");
    create_status_file_failed(gt.process_id,(char*)"JPEG Driver failed");
    remove_resources_gtt(&gt);
    exit(0);
}
break;
case MBGEN_ERROR_NO_RASTERS:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, open_input_gtt, No Image Raster found");
        create_status_file_failed(gt.process_id,(char*)"No Rasters found");
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
case MBGEN_ERROR_CANNOT_PROCESS_FILE:
    {
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, open_input_gtt, GDAL failed to Open the File");
        create_status_file_failed(gt.process_id,gt.input_filename);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
}
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Opening input file complete");
generate_metadata_gtt(&gt,&gm);
write_log((char*)objLogFileName.c_str(),(char*)"INFO:generating metadata complete");
create_status_file_progress(gt.process_id,0.0);

// Opening the MBTiles

func_result = open_mbtiles_gtt(&gt);
if(func_result == MBGEN_ERROR_SQLITE_OPEN_FAILED)
{
    write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, open_mbtiles_gtt, Opening MBTiles [FAILED]");
    create_status_file_failed(gt.process_id,(char*)"Opening MBTiles failed");
    remove_resources_gtt(&gt);
    exit(0);
}
write_log((char*)objLogFileName.c_str(),(char*)"INFO:open_mbtiles complete");
// Creating MBTiles

func_result = create_table_mbtiles_gtt(&gt);
if(func_result == MBGEN_ERROR_CREATE_TABLE_FAILED)
{
    write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, create_table_mbtiles_gtt, create table [FAILED]");
    create_status_file_failed(gt.process_id,(char*)"Creating Tables in MBTiles failed");
    remove_resources_gtt(&gt);
    close_mbtiles_gtt(&gt);
    exit(0);
}
write_log((char*)objLogFileName.c_str(),(char*)"INFO:create tables in mbtiles complete");
// Insert Metadata into MBTiles
func_result = insert_metadata_mbtiles_gtt(&gt);
if(func_result ==  MBGEN_ERROR_INSERT_ROW_FAILED)
{
    write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, insert_metadata_mbtiles_gtt, insert metadata rows [FAILED]");
    create_status_file_failed(gt.process_id,(char*)"Inserting Metadata in MBTiles failed");
    close_mbtiles_gtt(&gt);
    remove_resources_gtt(&gt);
    exit(0);
}
write_log((char*)objLogFileName.c_str(),(char*)"INFO:insert metadata into mbtiles complete");
printf("\n");
printf("0...");
// Generate Base tiles
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Generating base Tiles started");
func_result = generate_base_tiles_gtt(&gt,&gm);
switch(func_result)
{
    case GEOMAP_UTILS_TERM_REQUESTED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, termination requested\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, termination requested\n");
        create_status_file_term(gt.process_id,(char*)"generate_base_tiles_gtt:termination requested");
        string termFile;
        termFile.append(gt.process_id);
        termFile.append(".end");
        remove(termFile.c_str());
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_FILE_TILE_NOT_FOUND:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, tile not found in file system\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, tile not found in file system");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:tile not found in file system");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_FILE_IO_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, File I/O [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, File I/O [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:File I/O Error");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, Memory allocation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, Memory allocation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:Insufficient Memory");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_FILE_OPEN_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, File open failed [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, File open failed [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:File Open failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_INSERT_ROW_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, Insert base tile [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, Insert base tile [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:write tile failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_PNG_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, create PNG file [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, create PNG file [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:PNG creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_JPEG_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, create JPEG file [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, create JPEG file [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:JPEG creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_MEM_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, Memory Dataset creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, Memory Dataset creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:MEM buffer creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_WDS_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles, generate_base_tiles_gtt, Memory Dataset creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles, generate_base_tiles_gtt, write buffer creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_base_tiles_gtt:write data buffer creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
}//End of switch
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Generating base Tiles complete");
//Now Removing the Resourse of the Base tile
GDALClose(gt.in_ds);
gt.in_ds = NULL;

// Generate Overview tiles
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Start generating overview tiles");
func_result = generate_overview_tiles_gtt(&gt,&gm);
switch(func_result)
{
    case GEOMAP_UTILS_TERM_REQUESTED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt,Termination requested\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt,Termination requested");
        create_status_file_term(gt.process_id,(char*)"generate_overview_tiles_gtt:Termination requested");
        string termFile;
        termFile.append(gt.process_id);
        termFile.append(".end");
        remove(termFile.c_str());
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_WDS_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt,Write Buffer creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt,Write Buffer creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:Write Buffer creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt,Memory allocation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt,Memory allocation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:Insufficient Memory");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_QRY_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, Opening dataset for generating overview [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, Opening dataset for generating overview [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:Memory buffer creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_MEM_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, Memory buffer creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, Memory buffer creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:Memory buffer failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_PNG_CREATE_FAILED:
    {

        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, generate_overview_tiles:PNG creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, PNG creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:PNG creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_JPEG_CREATE_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, generate_overview_tiles:JPEG creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, JPEG creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:JPEG creation failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_FILE_IO_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, generate_overview_tiles,File I/O creation [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt,File I/O creation [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:File I/O Error");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_FILE_OPEN_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt,File Open [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, File Open [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:File Open failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_ERROR_INSERT_ROW_FAILED:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, Insert tiles [FAILED]\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, Insert tiles [FAILED]");
        create_status_file_failed(gt.process_id,(char*)"generate_overview_tiles_gtt:write tile failed");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
    case MBGEN_FILE_BASE_TILES_NOT_FOUND:
    {
        printf("ERROR:convert_mbtiles,generate_overview_tiles_gtt, Base tile not found\n");
        write_log((char*)objLogFileName.c_str(),(char*)"ERROR:convert_mbtiles,generate_overview_tiles_gtt, Base tile not found");
        create_status_file_failed(gt.process_id,(char*)"Base tiles not found");
        close_mbtiles_gtt(&gt);
        clean_tmp_files_gtt(&gt);
        remove_resources_gtt(&gt);
        exit(0);
    }
    break;
}//End of switch
write_log((char*)objLogFileName.c_str(),(char*)"INFO:generating overview tiles complete");
func_result = close_mbtiles_gtt(&gt);
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Closing MBTiles");
clean_tmp_files_gtt(&gt);
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Removing Temporary files");
remove_resources_gtt(&gt);
write_log((char*)objLogFileName.c_str(),(char*)"INFO:Removing Resources");
if(0 == func_result)
{
    remove((char*)objLogFileName.c_str());
}
#ifdef MBTILES_GEN
GDALDestroyDriverManager();
#endif
}
else
{
create_status_file_failed(process_id,(char*)"Bad input file names in parameters");
#ifdef MBTILES_GEN
GDALDestroyDriverManager();
#endif
exit(0);
}

return MBGEN_SUCCESS;
}
