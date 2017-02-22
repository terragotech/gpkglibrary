#include "config.h"
#include "gdal_to_tiles.h"
#include "latlong.h"
#include "global_mercator.h"
#include "utils.h"
#ifdef OS_UNIX_LINUX_BUILD
#include "png.h"
#include <unistd.h>
#else
#include "png.h"
#endif
#include "logger.h"
#include <cmath>
#include <spawn.h>
/*
* Cleans all the files created in the temporary folder
*/
///clean_tmp_files - Cleans all the PNG files created in the temporary folder
void clean_tmp_files_gtt(struct gdal_tiles *gt)
{
	char fpath[1024];
	fpath[0] = '\0';

#ifdef OS_UNIX_LINUX_BUILD
	
	if(NULL != gt->tmp_folder){
		if(strcmp(gt->image_type,"png") == 0)
		{
			sprintf(fpath,"rm -f %s/mbtiles/%s_*.%s",gt->tmp_folder,gt->os_process_id,"png");
		}
		else
		{
			sprintf(fpath,"rm -f %s/mbtiles/%s_*.%s",gt->tmp_folder,gt->os_process_id,"jpg");
		}
//		system(fpath);
        pid_t pid;
        char **environ;
        posix_spawn(&pid, fpath, NULL, NULL, NULL, environ);
        waitpid(pid, NULL, 0);
	}
	else
	{
		if(strcmp(gt->image_type,"png") == 0)
		{
			sprintf(fpath,"rm -f ./mbtiles/%s_*.%s",gt->os_process_id,"png");
		}
		else
		{
			sprintf(fpath,"rm -f ./mbtiles/%s_*.%s",gt->os_process_id,"jpg");
		}
//		system(fpath);
        pid_t pid;
        char **environ;
        posix_spawn(&pid, fpath, NULL, NULL, NULL, environ);
        waitpid(pid, NULL, 0);
	}
#else
	if(NULL != gt->tmp_folder){
		if(strcmp(gt->image_type,"png") == 0)
		{
			sprintf(fpath,"del %s\\mbtiles\\%s_*.%s",gt->tmp_folder,gt->os_process_id,"png");
		}
		else
		{
			sprintf(fpath,"del %s\\mbtiles\\%s_*.%s",gt->tmp_folder,gt->os_process_id,"jpg");
		}
		system(fpath);
	}
	else
	{
		if(strcmp(gt->image_type,"png") == 0)
		{
			sprintf(fpath,"del .\\mbtiles\\%s_*.%s",gt->os_process_id,"png");
		}
		else
		{
			sprintf(fpath,"del .\\mbtiles\\%s_*.%s",gt->os_process_id,"jpg");
		}
		system(fpath);
	}
#endif

}//void clean_tmp_files(struct gdal_tiles *gt)

/*
* Releases all the memory resources allocated by application
*/
///remove_resources - release all the system resources
void remove_resources_gtt(struct gdal_tiles *gt)
{
	if(NULL != gt->dataFromBand){
		free(gt->dataFromBand);
		gt->dataFromBand = NULL;
	}
	if(NULL != gt->mbtiles_file_name){
		free(gt->mbtiles_file_name);
		gt->mbtiles_file_name = NULL;
	}
	if(NULL != gt->tmp_folder){
		free(gt->tmp_folder);
		gt->tmp_folder = NULL;
	}
	if(NULL != gt->input_filename){
		free(gt->input_filename);
		gt->input_filename = NULL;
	}
	if(NULL != gt->in_ds)
	{
		GDALClose(gt->in_ds);
		gt->in_ds = NULL;
	}
	if(NULL != gt->process_id)
	{
		free(gt->process_id);
		gt->process_id = NULL;
	}
	
}//void remove_resources_gtt(struct gdal_tiles *gt)

/*
* clean_png_file - Module used to remove the black spots created in the PNG file
*/
///clean_png_file - Module used to remove the black spots created in the PNG file
///Process PNG of type RGB and RGBA

int clean_png_file(struct gdal_tiles *gt, char *file_name)
{
	int result = MBGEN_SUCCESS;
	int can_process_png = 0;
	char header[8];
	png_structp png_ptr;
	png_infop info_ptr;
	int width, height;
	png_byte color_type;
	png_byte bit_depth;

	FILE *fp = fopen(file_name, "rb");
	if(NULL != fp)
	{
		fread(header, 1, 8, fp);
		if (!png_sig_cmp((png_bytep)header, 0, 8)){
			png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
			if(NULL == png_ptr)
			{
				fclose(fp);
				return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
			}
			info_ptr = png_create_info_struct(png_ptr);
			if(NULL == info_ptr)
			{
				fclose(fp);
				return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
			}
			png_init_io(png_ptr, fp);
			png_set_sig_bytes(png_ptr, 8);

			png_read_info(png_ptr, info_ptr);

			width = png_get_image_width(png_ptr, info_ptr);
			height = png_get_image_height(png_ptr, info_ptr);
			color_type = png_get_color_type(png_ptr, info_ptr);
			bit_depth = png_get_bit_depth(png_ptr, info_ptr);
			
			//Process RGB (color Type 2) , RGBA (color Type 6) and 
			// PALETTE PNG images (color type 3),
			// of bit depth 8
			//http://www.w3.org/TR/PNG-Chunks.html

			if((color_type == PNG_COLOR_TYPE_RGB) || (color_type == PNG_COLOR_TYPE_RGBA) || (color_type == PNG_COLOR_TYPE_PALETTE))
			{
				if(bit_depth == 8)
				{
					can_process_png = 1;
				}
				else
				{
					can_process_png = 0;
				}
			}
			else
			{
				can_process_png = 0;
			}
			if (png_ptr && info_ptr) 
			{
				png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
				png_ptr = NULL;
				info_ptr = NULL;
			}
		}
		fclose(fp);
	}
	else
	{
		return MBGEN_FILE_TILE_NOT_FOUND;
	}
	if(can_process_png == 1)
	{
		gt->png_modified = 1;
		gt->wx = ((double)gt->wx / (double)gt->querysize) * 256;
		gt->wy = ((double)gt->wy / (double)gt->querysize) * 256;
		gt->xsize = ((double)gt->xsize / (double)gt->querysize) * 256;
		gt->ysize = ((double)gt->ysize / (double)gt->querysize) * 256;

		/********************** PROCESS THE PNG FILE *************************/
		char header[8];
		png_structp png_ptr;
		png_infop info_ptr;
		int width, height;
		png_byte color_type;
		png_byte bit_depth;
		int number_of_passes;
		png_bytep *row_pointers;
		png_bytep *row_pointers_alpha;

		FILE *fp = fopen(file_name, "rb");
		if(NULL != fp)
		{
			fread(header, 1, 8, fp);
			if (!png_sig_cmp((png_bytep)header, 0, 8))
			{
				png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
				if(NULL == png_ptr)
				{
					fclose(fp);
					return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
				}
				info_ptr = png_create_info_struct(png_ptr);
				if(NULL == info_ptr)
				{
					fclose(fp);
					return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
				}
				png_init_io(png_ptr, fp);
				png_set_sig_bytes(png_ptr, 8);
				png_read_info(png_ptr, info_ptr);

				width = png_get_image_width(png_ptr, info_ptr);
				height = png_get_image_height(png_ptr, info_ptr);
				color_type = png_get_color_type(png_ptr, info_ptr);
				bit_depth = png_get_bit_depth(png_ptr, info_ptr);

				if(color_type == PNG_COLOR_TYPE_PALETTE)
				{
					//Convert palette color to RGB 
					png_set_palette_to_rgb(png_ptr);
				}
				number_of_passes = png_set_interlace_handling(png_ptr);
				png_read_update_info(png_ptr, info_ptr);
									
				row_pointers = (png_bytep*)malloc(sizeof(png_bytep) * height);
				if(row_pointers == NULL)
				{
					if (png_ptr && info_ptr) 
					{
						png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
						png_ptr = NULL;
						info_ptr = NULL;
					}
					fclose(fp);
					return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
				}
				row_pointers_alpha = (png_bytep*)malloc(sizeof(png_bytep) * height);
				if(row_pointers_alpha == NULL)
				{
					if(row_pointers != NULL)
					{
						free(row_pointers);
					}
					if (png_ptr && info_ptr) 
					{
						png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
						png_ptr = NULL;
						info_ptr = NULL;
					}
					fclose(fp);
					return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
				}

				for(int y = 0; y < height; y++) 
				{
					row_pointers[y] = (png_byte*)malloc(png_get_rowbytes(png_ptr,info_ptr));
					if(row_pointers[y] == NULL)
					{
						for(int yidx = 0; yidx < y; yidx++)
						{
							free(row_pointers[yidx]);
						}
						if (png_ptr && info_ptr) 
						{
							png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
							png_ptr = NULL;
							info_ptr = NULL;
						}
						fclose(fp);
						return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
					}
					if((color_type == PNG_COLOR_TYPE_RGB) || (color_type == PNG_COLOR_TYPE_PALETTE))
					{
						//Convert RGB or PALETTE => RGBA
						row_pointers_alpha[y] = (png_byte*)malloc(width*(bit_depth/8)*4);
					}
					else
					{
						//Case of RGBA
						row_pointers_alpha[y] = (png_byte*)malloc(png_get_rowbytes(png_ptr,info_ptr));
					}
					if(row_pointers_alpha[y] == NULL)
					{
						for(int yidx = 0; yidx < y; yidx++)
						{
							free(row_pointers_alpha[yidx]);
						}
						for(int yidx = 0; yidx <= y; yidx++)
						{
							free(row_pointers[yidx]);
						}
						if (png_ptr && info_ptr) 
						{
							png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
							png_ptr = NULL;
							info_ptr = NULL;
						}
						fclose(fp);
						return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
					}
				}
				png_read_image(png_ptr, row_pointers);
				if (png_ptr && info_ptr) 
				{
					png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
					png_ptr = NULL;
					info_ptr = NULL;
				}
				fclose(fp);
				// End of Reading the PNG files

				//Now creating the PNG file
				FILE *fp1 = fopen(file_name, "wb");
				if(fp1 != NULL)
				{
					png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
					if(NULL == png)
					{
						fclose(fp1);
						for(int y = 0; y < height; y++) 
						{
							free(row_pointers[y]);
							free(row_pointers_alpha[y]);
						}
						free(row_pointers);
						free(row_pointers_alpha);

						return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
					}
					png_infop info = png_create_info_struct(png);
					if(NULL == info)
					{
						fclose(fp1);
						for(int y = 0; y < height; y++) 
						{
							free(row_pointers[y]);
							free(row_pointers_alpha[y]);
						}
						free(row_pointers);
						free(row_pointers_alpha);
						return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
					}
					//if(info)
					//{
						png_init_io(png, fp1);
						png_set_IHDR(png,info,width, height,bit_depth,PNG_COLOR_TYPE_RGBA,
								PNG_INTERLACE_NONE,PNG_COMPRESSION_TYPE_DEFAULT,
								PNG_FILTER_TYPE_DEFAULT);
						png_write_info(png, info);
						for(int y = 0; y < height; y++) 
						{
							png_bytep row = row_pointers[y];
							png_bytep row1 = row_pointers_alpha[y];
							for(int x = 0; x < width; x++) 
							{
								png_bytep px;
								//Input may be RGB or RGBA
								//Incase of PALETTE image, it has been converted to 
								//RGB above and hence the following code works
								
								if((color_type == PNG_COLOR_TYPE_RGB) || (color_type == PNG_COLOR_TYPE_PALETTE))
								{
									px = &(row[x * 3]);
								}
								else
								{
									px = &(row[x * 4]);
								}
								//Destination is always RGBA
								png_bytep px1 = &(row1[x * 4]);
								
								if((color_type == PNG_COLOR_TYPE_RGB) || (color_type == PNG_COLOR_TYPE_PALETTE))
								{
											px1[0] = px[0];
											px1[1] = px[1];
											px1[2] = px[2];
											px1[3] = 255;
								}
								else
								{
											px1[0] = px[0];
											px1[1] = px[1];
											px1[2] = px[2];
											px1[3] = 255;
								}
								//Make transparent
								if((y < gt->wy) || (y >= ((gt->wy + gt->ysize))) )
								{
									px1[3] = 0;	
								}
								if((x < gt->wx) || (x >= ((gt->wx + gt->xsize))) )
								{
									px1[3] = 0;	
								}
							}
						}
						png_write_image(png, row_pointers_alpha);
						png_write_end(png, NULL);
						
 						for(int y = 0; y < height; y++) 
						{
							free(row_pointers[y]);
							free(row_pointers_alpha[y]);
						}
						free(row_pointers);
						free(row_pointers_alpha);

						if (png && info) 
						{
							png_destroy_write_struct(&png,(png_infopp)&info);
							png = NULL;
						}
						fclose(fp1);
						//End of PNG write
					//}
				}
				else
				{
						for(int y = 0; y < height; y++) 
						{
							free(row_pointers[y]);
							free(row_pointers_alpha[y]);
						}
						free(row_pointers);
						free(row_pointers_alpha);
						return MBGEN_FILE_OPEN_FAILED;
				}
			}
		}
		else
		{
			return MBGEN_FILE_TILE_NOT_FOUND;
		}
	}//End of can process PNG
	return result;
}//int clean_png_file(struct gdal_tiles *gt, char *file_name)
/*
* Code to clean the linked list of Tile info
*/
///clear_all_elements : clean the linked list of Tile info
void clear_all_elements(struct gdal_tiles *gt)
{
	if(gt->ptrtile_info != NULL){
		struct tile_exists_info *ptrTileInfo = gt->ptrtile_info;
		while(ptrTileInfo->next != NULL)
		{
			struct tile_exists_info *ptrCurrentElement = ptrTileInfo;
			struct tile_exists_info *ptrNextElement = ptrTileInfo->next;
			free(ptrCurrentElement);
			ptrTileInfo = ptrNextElement;
		}
		free(ptrTileInfo);
		gt->ptrtile_info = NULL;
	}
}///void clear_all_elements(struct gdal_tiles *gt)


int insert_element(struct gdal_tiles *gt, struct tile_exists_info *ptrElement){
	int result = MBGEN_SUCCESS;

	if(gt->ptrtile_info == NULL){
		gt->ptrtile_info = (struct tile_exists_info *)malloc(sizeof(struct tile_exists_info));
		if(gt->ptrtile_info == NULL)
		{
			return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
		}
		struct tile_exists_info *ptrE = gt->ptrtile_info;
		ptrE->next = NULL;
		ptrE->tx = ptrElement->tx;	 
		ptrE->ty = ptrElement->ty;
		ptrE->tz = ptrElement->tz;
	}
	else
	{
		struct tile_exists_info *ptrTileInfo = gt->ptrtile_info;
		while(ptrTileInfo->next != NULL)
		{
			ptrTileInfo = ptrTileInfo->next;
		}
		ptrTileInfo->next = (struct tile_exists_info *)malloc(sizeof(struct tile_exists_info ));
		if(ptrTileInfo->next == NULL)
		{
			clear_all_elements(gt);
			return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
		}
		ptrTileInfo = ptrTileInfo->next;
		ptrTileInfo->next = NULL;
		ptrTileInfo->tx = ptrElement->tx;	 
		ptrTileInfo->ty = ptrElement->ty;
		ptrTileInfo->tz = ptrElement->tz;
	}
	return result;
}
int try_to_use_existing_tile(struct gdal_tiles *gtiles,int tx,int ty,int tz){

	char file_name[1024];
	char tmp_file_name[1024];
	int tile_found = 0;
	file_name[0] = '\0';
	tmp_file_name[0] = '\0';
#ifdef OS_UNIX_LINUX_BUILD
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s/mbtiles/%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
	}
	else
	{
		sprintf(tmp_file_name,"./%s/%s_%d_","mbtiles",gtiles->os_process_id,tz);
	}
#else
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s\\mbtiles\\%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
	}
	else
	{
		sprintf(tmp_file_name,".\\%s\\%s_%d_","mbtiles",gtiles->os_process_id,tz);
	}
#endif	

	strcat(file_name,tmp_file_name);

	sprintf(tmp_file_name,"%d_",tx);
	strcat(file_name,tmp_file_name);

	sprintf(tmp_file_name,"%d_",ty);
	strcat(file_name,tmp_file_name);

	if(strcmp(gtiles->image_type,"png") == 0)
	{
		strcat(file_name,"file.png");
	}
	else
	{
		strcat(file_name,"file.jpg");
	}

	FILE *fp = fopen(file_name,"rb");
	if(NULL != fp){
		tile_found = 1;
		fclose(fp);
	}
	else
	{
		tile_found = 0;	
	}
	
	return tile_found;
}

int check_for_children(struct gdal_tiles *gtiles,int tx,int ty,int tz)
{
	int x = 0;
	int y = 0;
	
	int cx=0,cy=0;
	int tileposy = 0;
	int tileposx = 0;
	char **papszOptions = NULL;
	sqlite3_stmt *stmt = NULL;
//	char *tail;
	char sql_statement[1024];
	sql_statement[0] = '\0';

	tile_exists_info tef;

	int tile_found = 0;
	gtiles->tile_found_count = 0;
	
	int result = MBGEN_SUCCESS;

	for(y=2*ty;y<(2*ty+2);y++){
		for(x=2*tx;x<(2*tx+2);x++){
			tile_found = try_to_use_existing_tile(gtiles,x,y,tz+1);
			
			tef.tx = x;
			tef.ty = y;
			tef.tz = tz+1;
			if(tile_found == 1){
				result = insert_element(gtiles,&tef);
				if(result < 0){
					return result;
				}
				gtiles->tile_found_count++;
			}
		}
	}
	//End of for
	return result;
}//int check_for_children(struct gdal_tiles *gtiles,int tx,int ty,int tz)
#if 0
void write_overview_tile_from_raster(struct gdal_tiles *gtiles,int tx,int ty,int tz,xyzzy *process_tile_info,int idx){
	int b_idx = 0;
	
	GDALRasterBandH hBand;
	char file_name[1024];
	char tmp_file_name[1024];
	char **papszOptions = NULL;
	sqlite3_stmt *stmt = NULL;
	file_name [0] = '\0';
	tmp_file_name[0] = '\0';

	
	if(process_tile_info->rx + process_tile_info->rxsize > gtiles->image_width)
	{
		process_tile_info->rxsize = gtiles->image_width - process_tile_info->rx;
	}
	if(process_tile_info->ry + process_tile_info->rysize > gtiles->image_height)
	{
		process_tile_info->rysize = gtiles->image_height - process_tile_info->ry;
		process_tile_info->wysize = process_tile_info->rysize;
	}



	gtiles->write_ds = GDALCreate(gtiles->drvMEM,"",gtiles->querysize,gtiles->querysize,gtiles->bands,gtiles->pixelDataType,NULL);
	

	/* Code for handling Color Tables across the bands */
	for(b_idx=1;b_idx<=gtiles->bands;b_idx++)
	{
		hBand = GDALGetRasterBand(gtiles->in_ds,b_idx);
		if(hBand != NULL){
			if( GDALGetRasterColorTable( hBand ) != NULL )
			{
				GDALSetRasterColorTable(GDALGetRasterBand(gtiles->write_ds,b_idx),GDALGetRasterColorTable( hBand ));		
			}
		}
	}

	
	GDALDataset *poSrcDS = (GDALDataset *)gtiles->in_ds;
	int raster_count = poSrcDS->GetRasterCount();
	
	for(int r_idx=1;r_idx<=raster_count;r_idx++){
		GDALRasterBand* poOvrBand = poSrcDS->GetRasterBand(r_idx)->GetOverview(idx);
		CPLErr result = GDALRasterIO(poOvrBand,GF_Read,
					process_tile_info->rx,process_tile_info->ry,
					process_tile_info->rxsize,process_tile_info->rysize,
					gtiles->dataFromBand,
					process_tile_info->rxsize,process_tile_info->rysize,
					gtiles->pixelDataType,
					0,0);
		if(result == CE_None)
		{
					
					GDALRasterBandH poOvrBandWR = GDALGetRasterBand(gtiles->write_ds,r_idx);
					result = GDALRasterIO(poOvrBandWR,GF_Write,
						process_tile_info->wx,process_tile_info->wy,
						process_tile_info->wxsize,process_tile_info->wysize,
					gtiles->dataFromBand,
					process_tile_info->rxsize,process_tile_info->rysize,
					gtiles->pixelDataType,
					0,0);
					if(result == CE_None){
						//printf("\nSuccess");
					}
		}

						gtiles->wx = process_tile_info->wx;
						gtiles->wy = process_tile_info->wy;
						gtiles->xsize = process_tile_info->wxsize;
						gtiles->ysize = process_tile_info->wysize;
	}

	/* Must Write after processing all the bands */


						GDALDatasetH dstile = GDALCreate(gtiles->drvMEM,"",gtiles->tileSize,gtiles->tileSize,gtiles->bands,gtiles->pixelDataType,NULL);
						int dstile_raster_count = GDALGetRasterCount(dstile);
						for(b_idx=1;b_idx<=dstile_raster_count;b_idx++){
							GDALRasterBandH hBand1 = GDALGetRasterBand( gtiles->write_ds, b_idx );
							GDALRasterBandH hBand2 = GDALGetRasterBand( dstile, b_idx );
							if(GDALRegenerateOverviews(hBand1,1,&hBand2,"average",NULL,NULL) == CE_None){
								//printf("\nGood");
							}
						}
#ifdef OS_UNIX_LINUX_BUILD
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s/mbtiles/%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
	}
	else
	{
		sprintf(tmp_file_name,"./%s/%s_%d_","mbtiles",gtiles->os_process_id,tz);
	}
#else
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s\\mbtiles\\%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
	}
	else
	{
		sprintf(tmp_file_name,".\\%s\\%s_%d_","mbtiles",gtiles->os_process_id,tz);
	}
#endif	

						
						strcat(file_name,tmp_file_name);

						sprintf(tmp_file_name,"%d_",tx);
						strcat(file_name,tmp_file_name);

						sprintf(tmp_file_name,"%d_",ty);
						strcat(file_name,tmp_file_name);

						strcat(file_name,"file.png");

						gtiles->png_ds = GDALCreateCopy(gtiles->drvPNG,file_name,dstile,0,papszOptions,NULL,NULL);
						GDALClose(dstile);
						GDALClose(gtiles->write_ds);
						GDALClose(gtiles->png_ds);

						clean_png_file(gtiles,file_name);
						/*
						gtiles->png_ds = GDALCreateCopy(gtiles->drvPNG,file_name,gtiles->write_ds,0,papszOptions,NULL,NULL);
						GDALClose(gtiles->write_ds);
						GDALClose(gtiles->png_ds);
						*/
						unsigned int file_size = 0;
							unsigned char *ptrFileBinData = NULL;
							FILE *fp1 = fopen(file_name,"rb");
							if(fp1 != NULL)
							{
								fseek(fp1,0,SEEK_END);
								file_size = ftell(fp1);
								fseek(fp1,0,SEEK_SET);
								//gtiles->fsi[tz].fileSize += file_size;
								ptrFileBinData = (unsigned char*)malloc(file_size);
								if(ptrFileBinData != NULL){
										fread(ptrFileBinData,file_size,1,fp1);
								}
								fclose(fp1);		
							}// End of file operation
							if(ptrFileBinData != NULL)
							{
								/*
								sprintf(sql_statement,"insert into tiles (zoom_level, tile_column, tile_row, tile_data) values (%d, %d, %d, ?);", tz,tx,ty);
								sqlite3_prepare_v2(gtiles->db2,(const char*)sql_statement,strlen(sql_statement)+1,&stmt,(const char**)&tail);
								sqlite3_bind_blob(stmt,1,(void*)ptrFileBinData,file_size,SQLITE_TRANSIENT);
								if(sqlite3_step(stmt)!=SQLITE_DONE) 
									printf("Error message: %s\n", sqlite3_errmsg(gtiles->db2));
								sqlite3_finalize(stmt);
								free(ptrFileBinData);
								*/
								write_mbtiles(gtiles,tz,tx,ty,ptrFileBinData,file_size);
							}
	//GDALRasterIO
	 

}
#endif
int write_overview_tile(struct gdal_tiles *gtiles,int tx,int ty,int tz,xyzzy *process_tile_info){
	
	int result = MBGEN_SUCCESS;
	int x,y,cx,cy,tileposy,tileposx;
	
	x = 0;
	y = 0;
	cx = 0;
	cy = 0;
	tileposx = 0;
	tileposy = 0;
	char **papszOptions = NULL;
	sqlite3_stmt *stmt = NULL;
	char sql_statement[1024];
	sql_statement[0] = '\0';


	int tile_cnt = 0;
	char file_name[1024];
	char tmp_file_name[1024];
	int b_idx;
	int raster_bands;

	char quality[25];
	char zlevel[25];
	
	quality[0] = '\0';
	zlevel[0] = '\0';

	if(process_tile_info->rx + process_tile_info->rxsize > gtiles->image_width)
	{
		process_tile_info->rxsize = gtiles->image_width - process_tile_info->rx;
	}
	if(process_tile_info->ry + process_tile_info->rysize > gtiles->image_height)
	{
		process_tile_info->rysize = gtiles->image_height - process_tile_info->ry;
	}

	result = check_for_children(gtiles,tx,ty,tz);

	if(result < 0)
	{
		return result;
	}

	if(gtiles->ptrtile_info == NULL)
	{
		return MBGEN_FILE_BASE_TILES_NOT_FOUND;
	}
	tile_exists_info *ptile_if = gtiles->ptrtile_info;
	int create_bands = 0;
	create_bands = gtiles->bands;

	if(strcmp(gtiles->image_type,"png") == 0)
	{
		if(gtiles->png_modified == 1)
		{
			create_bands = 4; 
		}
		else
		{
			create_bands = gtiles->bands;
		}
	}

	gtiles->write_ds = GDALCreate(gtiles->drvMEM,"",gtiles->tileSize*2,gtiles->tileSize*2,create_bands,gtiles->pixelDataType,NULL);
	if(gtiles->write_ds == NULL)
	{
		clear_all_elements(gtiles);
		return MBGEN_ERROR_WDS_CREATE_FAILED;
	}
	gtiles->dataFromBand = (unsigned char*)malloc(gtiles->tileSize * gtiles->tileSize * create_bands * gtiles->bytes_per_pixel);
	unsigned char *ptrDataFromFile = gtiles->dataFromBand;
	if(NULL == ptrDataFromFile)
	{
		clear_all_elements(gtiles);
		if(gtiles->write_ds != NULL)
		{
			GDALClose(gtiles->write_ds);
		}
		return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
	}

	do
	{
		tile_exists_info tf;
		tf.tx = ptile_if->tx;
		tf.ty = ptile_if->ty;
		tf.tz = ptile_if->tz;
		ptile_if = ptile_if->next; 

		cx = tf.tx;
		cy = tf.ty;
		if ( (((ty==0) && (cy==1)) || ((ty!=0) && (cy % (2*ty)))) != 0){
			tileposy = 0;
		}
		else
		{
			tileposy = gtiles->tileSize;
		}
		if(tx){
			tileposx = cx % (2*tx) * gtiles->tileSize;
		}
		else if((tx==0) && (cx==1)){
			tileposx = gtiles->tileSize;
		}
		else
		{
			tileposx = 0;
		}
				
				
		file_name[0] = '\0';
		tmp_file_name[0] = '\0';

#ifdef OS_UNIX_LINUX_BUILD
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s/mbtiles/%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz+1);
	}
	else
	{
		sprintf(tmp_file_name,"./%s/%s_%d_","mbtiles",gtiles->os_process_id,tz+1);
	}
#else
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s\\mbtiles\\%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz+1);
	}
	else
	{
		sprintf(tmp_file_name,".\\%s\\%s_%d_","mbtiles",gtiles->os_process_id,tz+1);
	}
#endif		
		
		strcat(file_name,tmp_file_name);

		sprintf(tmp_file_name,"%d_",cx);
		strcat(file_name,tmp_file_name);

		sprintf(tmp_file_name,"%d_",cy);
		strcat(file_name,tmp_file_name);

		if(strcmp(gtiles->image_type,"png") == 0)
		{
			strcat(file_name,"file.png");
		}
		else
		{
			strcat(file_name,"file.jpg");
		}

		GDALDatasetH dsquerytile = GDALOpen(file_name, GA_ReadOnly);
		if(dsquerytile == NULL)
		{
			clear_all_elements(gtiles);
			if(gtiles->write_ds != NULL)
			{
				GDALClose(gtiles->write_ds);
			}
			return MBGEN_ERROR_QRY_CREATE_FAILED;
		}
		int image_height;
		int image_width;
		image_height = GDALGetRasterYSize(dsquerytile); 
		image_width = GDALGetRasterXSize(dsquerytile);
		GDALRasterBandH hBand = GDALGetRasterBand( dsquerytile, 1 );
		GDALDataType pixelDataType = GDALGetRasterDataType(hBand);
		int bytes_per_pixel = GDALGetDataTypeSize(pixelDataType) / 8;
		raster_bands = GDALGetRasterCount(dsquerytile);
		
		int b_idx = 0;
		
		for(b_idx=1;b_idx<=gtiles->bands;b_idx++)
		{
			hBand = GDALGetRasterBand(dsquerytile,b_idx);
			if(hBand != NULL){
				if( GDALGetRasterColorTable( hBand ) != NULL )
				{
					GDALSetRasterColorTable(GDALGetRasterBand(gtiles->write_ds,b_idx),GDALGetRasterColorTable( hBand ));		
				}
			}
		}

		if(NULL != ptrDataFromFile)
		{
			if(GDALDatasetRasterIO(dsquerytile,
				GF_Read,
				0,0,
				gtiles->tileSize,gtiles->tileSize,
				ptrDataFromFile,
				gtiles->tileSize,gtiles->tileSize,
				pixelDataType,
				raster_bands,
				NULL,
				0,0,0) == 0)
			{
				
				GDALRasterBandH hBand;

				for(b_idx=1;b_idx<=gtiles->bands;b_idx++)
				{
					hBand = GDALGetRasterBand(dsquerytile,b_idx);
					if(hBand != NULL){
						if( GDALGetRasterColorTable( hBand ) != NULL )
						{
							GDALSetRasterColorTable(GDALGetRasterBand(gtiles->write_ds,b_idx),GDALGetRasterColorTable( hBand ));		
						}
					}
				}

				if(GDALDatasetRasterIO(gtiles->write_ds,
				GF_Write,
				tileposx,tileposy,
				gtiles->tileSize,gtiles->tileSize,
				ptrDataFromFile,
				gtiles->tileSize,gtiles->tileSize,
				pixelDataType,
				raster_bands,
				NULL,
				0,0,0) == 0){
					//printf("\n Success");
							
				}
			}

		}
		GDALClose(dsquerytile);
	
	}while(ptile_if != NULL);
	clear_all_elements(gtiles);
	
	GDALDatasetH dstile = GDALCreate(gtiles->drvMEM,"",gtiles->tileSize,gtiles->tileSize,create_bands,gtiles->pixelDataType,NULL);
	if(dstile == NULL){
		if(gtiles->write_ds != NULL)
		{
			GDALClose(gtiles->write_ds);
		}
		return MBGEN_ERROR_MEM_CREATE_FAILED;
	}
	int dstile_raster_count = GDALGetRasterCount(dstile);
	
	
	for(b_idx=1;b_idx<=dstile_raster_count;b_idx++){
		GDALRasterBandH hBand1 = GDALGetRasterBand( gtiles->write_ds, b_idx );
		GDALRasterBandH hBand2 = GDALGetRasterBand( dstile, b_idx );
		if(GDALRegenerateOverviews(hBand1,1,&hBand2,"average",NULL,NULL) == CE_None){
			//printf("\nGood");
		}
	}

	GDALRasterBandH hBand;
	
	for(b_idx=1;b_idx<=gtiles->bands;b_idx++)
	{
		hBand = GDALGetRasterBand(gtiles->write_ds,b_idx);
		if(hBand != NULL){
			if( GDALGetRasterColorTable( hBand ) != NULL )
			{
				GDALSetRasterColorTable(GDALGetRasterBand(dstile,b_idx),GDALGetRasterColorTable( hBand ));		
			}
		}
	}
	
	file_name[0] = '\0';
	tmp_file_name[0] = '\0';
#ifdef OS_UNIX_LINUX_BUILD
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s/mbtiles/%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
	}
	else
	{
		sprintf(tmp_file_name,"./%s/%s_%d_","mbtiles",gtiles->os_process_id,tz);
	}
#else
	if(NULL != gtiles->tmp_folder)
	{
		sprintf(tmp_file_name,"%s\\mbtiles\\%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
	}
	else
	{
		sprintf(tmp_file_name,".\\%s\\%s_%d_","mbtiles",gtiles->os_process_id,tz);
	}
#endif	
	strcat(file_name,tmp_file_name);

	sprintf(tmp_file_name,"%d_",tx);
	strcat(file_name,tmp_file_name);

	sprintf(tmp_file_name,"%d_",ty);
	strcat(file_name,tmp_file_name);
	if(strcmp(gtiles->image_type,"png") == 0)
	{
		strcat(file_name,"file.png");
		sprintf(zlevel,"ZLEVEL=%s",gtiles->ZLEVEL);
		papszOptions = CSLAddString( papszOptions,zlevel);
		gtiles->png_ds = GDALCreateCopy(gtiles->drvPNG,file_name,dstile,0,papszOptions,NULL,NULL);
		if(gtiles->png_ds == NULL)
		{
			if(gtiles->write_ds != NULL)
			{
				GDALClose(gtiles->write_ds);
			}
			if(dstile != NULL)
			{
				GDALClose(dstile);
			}
			if (papszOptions != NULL) 
			{
				CSLDestroy (papszOptions);
			}
			return MBGEN_ERROR_PNG_CREATE_FAILED;
		}
		GDALClose(gtiles->write_ds);
		GDALClose(gtiles->png_ds);
		GDALClose(dstile);
		if (papszOptions != NULL) 
		{
			CSLDestroy (papszOptions);
		}
	}
	else
	{
		strcat(file_name,"file.jpg");
		sprintf(quality,"QUALITY=%s",gtiles->QUALITY);
		papszOptions = CSLAddString( papszOptions,quality);
		gtiles->jpg_ds = GDALCreateCopy(gtiles->drvJPG,file_name,dstile,0,papszOptions,NULL,NULL);
		if(gtiles->jpg_ds == NULL)
		{
			if(gtiles->write_ds != NULL)
			{
				GDALClose(gtiles->write_ds);
			}
			if(dstile != NULL)
			{
				GDALClose(dstile);
			}
			if (papszOptions != NULL) 
			{
				CSLDestroy (papszOptions);
			}
			return MBGEN_ERROR_JPEG_CREATE_FAILED;
		}
		GDALClose(gtiles->write_ds);
		GDALClose(gtiles->jpg_ds);
		GDALClose(dstile);
		if (papszOptions != NULL) 
		{
			CSLDestroy (papszOptions);
		}
	}

	

	unsigned int file_size = 0;
	unsigned char *ptrFileBinData = NULL;
	FILE *fp1 = fopen(file_name,"rb");
	if(fp1 != NULL)
	{
		fseek(fp1,0,SEEK_END);
		file_size = ftell(fp1);
		fseek(fp1,0,SEEK_SET);
		ptrFileBinData = (unsigned char*)malloc(file_size);
		if(ptrFileBinData != NULL)
		{
			result = fread(ptrFileBinData,file_size,1,fp1);
			if(result < 0)
			{

				result = MBGEN_FILE_IO_FAILED;
			}
			else
			{
				result = MBGEN_SUCCESS;
			}
		}
		else
		{
			result = MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;	
		}
		fclose(fp1);		
	}// End of file operation
	else
	{
		result = MBGEN_FILE_OPEN_FAILED;
	}
	if((ptrFileBinData != NULL) && (result == MBGEN_SUCCESS))
	{
		result = write_mbtiles_gtt(gtiles,tz,tx,ty,ptrFileBinData,file_size);
	}
	if(ptrFileBinData != NULL){
		free(ptrFileBinData);
		ptrFileBinData = NULL;
	}
	/* !!!!!!!!!!!!! Memory Clean up Section !!!!!!!!!!!!!!!!!!!*/
		if(NULL != gtiles->dataFromBand){
			free(gtiles->dataFromBand);
			gtiles->dataFromBand = NULL;
		}
	/* !!!!!!!!!!!!!! End Memory Clean up !!!!!!!!!!!!!!!!!!!!!!*/	
	return result;
	/*
	MBGEN_ERROR_WDS_CREATE_FAILED
GN_ERROR_MEMALLOCATION_FAILED
MBGEN_ERROR_QRY_CREATE_FAILED
MBGEN_ERROR_MEM_CREATE_FAILED
MBGEN_ERROR_PNG_CREATE_FAILED
MBGEN_ERROR_JPEG_CREATE_FAILED
MBGEN_FILE_IO_FAILED
MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED
MBGEN_FILE_OPEN_FAILED
MBGEN_ERROR_INSERT_ROW_FAILED
*/
}//int write_overview_tile(struct gdal_tiles *gtiles,int tx,int ty,int tz,xyzzy *process_tile_info)
int write_base_tile(struct gdal_tiles *gtiles,int tx,int ty,int tz,xyzzy *process_tile_info)
{
	int b_idx = 0;
	int result = 0;
	GDALRasterBandH hBand;
	char file_name[MBGEN_LONG_STRING+1];
	char tmp_file_name[MBGEN_LONG_STRING+1];
	char quality[25];
	char zlevel[25];

	char **papszOptions = NULL;
	sqlite3_stmt *stmt = NULL;
	file_name [0] = '\0';
	tmp_file_name[0] = '\0';
	quality[0] = '\0';
	zlevel[0] = '\0';

	/*
	Incase of the tile at the corner to fix the distortion 
	value calculated at the remove_distortion function will be used
	*/
	
	//Following code fixes the tile distortion, with the help of the 
	//remove distortion called at the generate_base tiles
	
	if(process_tile_info->rx + process_tile_info->rxsize > gtiles->image_width)
	{
		process_tile_info->rxsize = gtiles->image_width - process_tile_info->rx;
		if(gtiles->corner_tile == 1){
			process_tile_info->wxsize = gtiles->querysize * gtiles->aspect_ratio;
		}
		else
		{
			if(process_tile_info->rxsize >= process_tile_info->rysize){
				gtiles->aspect_ratio = (double)process_tile_info->rysize/(double)process_tile_info->rxsize;
			}
			else
			{
				gtiles->aspect_ratio = (double)process_tile_info->rxsize/(double)process_tile_info->rysize;
			}
			process_tile_info->wxsize = gtiles->querysize * gtiles->aspect_ratio;
		}
	}
	if(process_tile_info->ry + process_tile_info->rysize > gtiles->image_height)
	{
		process_tile_info->rysize = gtiles->image_height - process_tile_info->ry;
		if(gtiles->corner_tile == 1){
			process_tile_info->wysize = gtiles->querysize * gtiles->aspect_ratio;
		}
		else
		{
			if(process_tile_info->rxsize >= process_tile_info->rysize){
				gtiles->aspect_ratio = (double)process_tile_info->rysize/(double)process_tile_info->rxsize;
			}
			else
			{
				gtiles->aspect_ratio = (double)process_tile_info->rxsize/(double)process_tile_info->rysize;
			}
			process_tile_info->wysize = gtiles->querysize * gtiles->aspect_ratio;
		}
		
	}
	//End of distortion fix code 

	gtiles->write_ds = GDALCreate(gtiles->drvMEM,"",gtiles->querysize,gtiles->querysize,gtiles->bands,gtiles->pixelDataType,NULL);
	if(gtiles->write_ds == NULL)
	{
		return MBGEN_ERROR_WDS_CREATE_FAILED;
	}
	// Code for handling Color Tables across the bands
	// Case of PALETTED images
	for(b_idx=1;b_idx<=gtiles->bands;b_idx++)
	{
		hBand = GDALGetRasterBand(gtiles->in_ds,b_idx);
		if(hBand != NULL){
			if( GDALGetRasterColorTable( hBand ) != NULL )
			{
				GDALSetRasterColorTable(GDALGetRasterBand(gtiles->write_ds,b_idx),GDALGetRasterColorTable( hBand ));		
			}
		}
	}
	//End of Code for handling Color Tables across the bands
	
	if(GDALDatasetRasterIO(gtiles->in_ds,
						GF_Read,
						process_tile_info->rx,process_tile_info->ry,
						process_tile_info->rxsize,process_tile_info->rysize,
						gtiles->dataFromBand,
						process_tile_info->rxsize,process_tile_info->rysize,
						gtiles->pixelDataType,
						gtiles->bands,
						NULL,
						0,0,0) == CE_None)
	{
					if(GDALDatasetRasterIO(gtiles->write_ds,
					GF_Write,
					process_tile_info->wx,process_tile_info->wy,
					process_tile_info->wxsize,process_tile_info->wysize,
					gtiles->dataFromBand,
					process_tile_info->rxsize,process_tile_info->rysize,
					gtiles->pixelDataType,
					(gtiles->bands),
					NULL,
					0,0,0) == CE_None)
					{

						gtiles->wx = process_tile_info->wx;
						gtiles->wy = process_tile_info->wy;
						gtiles->xsize = process_tile_info->wxsize;
						gtiles->ysize = process_tile_info->wysize;

						GDALDatasetH dstile = GDALCreate(gtiles->drvMEM,"",gtiles->tileSize,gtiles->tileSize,gtiles->bands,gtiles->pixelDataType,NULL);
						if(dstile == NULL)
						{
							if(gtiles->write_ds != NULL)
							{
								GDALClose(gtiles->write_ds);
							}
							return MBGEN_ERROR_MEM_CREATE_FAILED;
						}
						int dstile_raster_count = GDALGetRasterCount(dstile);
						for(b_idx=1;b_idx<=dstile_raster_count;b_idx++){
							GDALRasterBandH hBand1 = GDALGetRasterBand( gtiles->write_ds, b_idx );
							GDALRasterBandH hBand2 = GDALGetRasterBand( dstile, b_idx );
							if(GDALRegenerateOverviews(hBand1,1,&hBand2,"average",NULL,NULL) == CE_None){
								//printf("\nGood");
							}
						}
#ifdef OS_UNIX_LINUX_BUILD
						if(NULL != gtiles->tmp_folder)
						{
							sprintf(tmp_file_name,"%s/mbtiles/%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
						}
						else
						{
							sprintf(tmp_file_name,"./%s/%s_%d_","mbtiles",gtiles->os_process_id,tz);
						}
#else
						if(NULL != gtiles->tmp_folder)
						{
							sprintf(tmp_file_name,"%s\\mbtiles\\%s_%d_",gtiles->tmp_folder,gtiles->os_process_id,tz);
						}
						else
						{
							sprintf(tmp_file_name,".\\%s\\%s_%d_","mbtiles",gtiles->os_process_id,tz);
						}
#endif	
						
						strcat(file_name,tmp_file_name);

						sprintf(tmp_file_name,"%d_",tx);
						strcat(file_name,tmp_file_name);

						sprintf(tmp_file_name,"%d_",ty);
						strcat(file_name,tmp_file_name);
						
						if(strcmp(gtiles->image_type,"png") == 0)
						{
							strcat(file_name,"file.png");
						}
						else
						{
							strcat(file_name,"file.jpg");
						}

						for(b_idx=1;b_idx<=gtiles->bands;b_idx++)
						{
							hBand = GDALGetRasterBand(gtiles->in_ds,b_idx);
							if(hBand != NULL){
								if( GDALGetRasterColorTable( hBand ) != NULL )
								{
									GDALSetRasterColorTable(GDALGetRasterBand(dstile,b_idx),GDALGetRasterColorTable( hBand ));		
								}
							}
						}

						if(strcmp(gtiles->image_type,"png") == 0)
						{
							sprintf(zlevel,"ZLEVEL=%s",gtiles->ZLEVEL);
							papszOptions = CSLAddString( papszOptions,zlevel);

							gtiles->png_ds = GDALCreateCopy(gtiles->drvPNG,file_name,dstile,0,papszOptions,NULL,NULL);
							if(gtiles->png_ds == NULL)
							{
								if(gtiles->write_ds != NULL)
								{
									GDALClose(gtiles->write_ds);
								}
								if(dstile != NULL){
									GDALClose(dstile);
								}
								if (papszOptions != NULL) 
								{
									CSLDestroy (papszOptions);
								}
								return MBGEN_ERROR_PNG_CREATE_FAILED;
							}
							GDALClose(dstile);
							GDALClose(gtiles->write_ds);
							GDALClose(gtiles->png_ds);
							if (papszOptions != NULL) 
							{
								CSLDestroy (papszOptions);
							}
 							result = clean_png_file(gtiles,file_name);
							if(result < 0)
							{
								return result;
							}
						}
						else
						{
							sprintf(quality,"QUALITY=%s",gtiles->QUALITY);
							papszOptions = CSLAddString( papszOptions,quality);
							gtiles->jpg_ds = GDALCreateCopy(gtiles->drvJPG,file_name,dstile,0,papszOptions,NULL,NULL);
							if(gtiles->jpg_ds == NULL)
							{
								if(gtiles->write_ds != NULL)
								{
									GDALClose(gtiles->write_ds);
								}
								if(dstile != NULL){
									GDALClose(dstile);
								}
								if (papszOptions != NULL) 
								{
									CSLDestroy (papszOptions);
								}
								return MBGEN_ERROR_JPEG_CREATE_FAILED;
							}
							GDALClose(dstile);
							GDALClose(gtiles->write_ds);
							GDALClose(gtiles->jpg_ds);
							if (papszOptions != NULL) 
							{
								CSLDestroy (papszOptions);
							}
						}
						unsigned int file_size = 0;
						unsigned char *ptrFileBinData = NULL;
						FILE *fp1 = fopen(file_name,"rb");
						if(fp1 != NULL)
						{
							fseek(fp1,0,SEEK_END);
							file_size = ftell(fp1);
							fseek(fp1,0,SEEK_SET);
							ptrFileBinData = (unsigned char*)malloc(file_size);
							if(ptrFileBinData != NULL)
							{
									result = fread(ptrFileBinData,file_size,1,fp1);
									if(result < 0)
									{
										result = MBGEN_FILE_IO_FAILED;
									}
									else
									{
										result = MBGEN_SUCCESS;
									}
							}
							else
							{
								result = MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
							}
							fclose(fp1);		
						}// End of file operation
						else
						{
							result =  MBGEN_FILE_OPEN_FAILED;
						}
						/********************************************************************/
						if((ptrFileBinData != NULL) && (result == MBGEN_SUCCESS))
						{
							result = write_mbtiles_gtt(gtiles,tz,tx,ty,ptrFileBinData,file_size);
						}
						if(ptrFileBinData != NULL){
							free(ptrFileBinData);
							ptrFileBinData = NULL;
						}
					}
	}
	return result;
	/*
	MBGEN_FILE_IO_FAILED
	MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED
	MBGEN_FILE_OPEN_FAILED
	MBGEN_ERROR_INSERT_ROW_FAILED
	MBGEN_ERROR_PNG_CREATE_FAILED
	MBGEN_ERROR_MEM_CREATE_FAILED
	MBGEN_ERROR_WDS_CREATE_FAILED
	MBGEN_ERROR_JPEG_CREATE_FAILED
	*/
}//write_base_tile(struct gdal_tiles *gtiles,int tx,int ty,int tz,xyzzy *process_tile_info)

/*
* set_input_filename_gtt
* Set the input file name in the gdal_tiles structure
*/
/// set_input_filename_gtt
/// Set the input file name in the gdal_tiles structure
int set_input_filename_gtt(struct gdal_tiles *gtiles,char *filename){
	int result = MBGEN_SUCCESS;
	if((NULL == gtiles) || (NULL == filename))
	{
		return MBGEN_BAD_INPUT_PARAMETERS;
	}
	if(NULL != filename){
		gtiles->input_filename = (char*) malloc(strlen(filename)+1);
		if(NULL != gtiles->input_filename){
			strcpy(gtiles->input_filename,filename);		
		}
		else
		{
			result = MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
		}
	}
	return result;
}//int set_input_filename_gtt(struct gdal_tiles *gtiles,char *filename)
/*
* geo_query
* Function converts the request in meters to image co-ordinates to fetch from Image Raster
* and process also computes the co-ordinates in the tile 256x256
*/
/// geo_query
/// Function converts the request in meters to image co-ordinates to fetch from Image Raster
/// and process also computes the co-ordinates in the tile 256x256

void geo_query(struct global_mercator *gm, struct gdal_tiles *gtiles,double ulx, double uly, double lrx, double lry,
	int *rx,int *ry,
	int *rxsize,int *rysize,
	int *wx, int *wy,
	int *wxsize, int *wysize,
	double querysize = 0)
{
	double rxshift;
	double ryshift;

	*rx = (int)((ulx - gtiles->in_gt[0]) / gtiles->in_gt[1]) + 0.001;
	*ry = (int)((uly - gtiles->in_gt[3]) / gtiles->in_gt[5] + 0.001);

	*rxsize = (int)((lrx - ulx) / gtiles->in_gt[1] + 0.5);
	*rysize = (int)((lry - uly) / gtiles->in_gt[5] + 0.5);

	
	if(querysize == 0)
	{
		*wxsize = *rxsize;
		*wysize = *rysize;
	}
	else
	{
		*wxsize = querysize;
		*wysize = querysize;
	}
	
	*wx = 0;
	if (*rx < 0){
		rxshift = abs(*rx);
		*wx = (int)((double)*wxsize * ((double) (rxshift) / (double)(*rxsize)));
		*wxsize = *wxsize - *wx;
		*rxsize = *rxsize - (int)(*rxsize *  (rxshift / (double)*rxsize));
		*rx = 0;
	}
	if(*rx+*rxsize > gtiles->image_width){
		*wxsize = (int) *wxsize * ( (double) (gtiles->image_width - *rx) / (double)*rxsize );
		*rxsize = gtiles->image_width - *rx;
	}
	*wy = 0;
	if(*ry < 0){
		ryshift = abs(*ry);
		*wy = (int) (*wysize * ((double) (ryshift) / (double) (*rysize)));
		*wysize = *wysize - *wy;
		*rysize = *rysize - (int)(*rysize * ( (double) (ryshift) / (double) *rysize ));
		*ry = 0;
		if(*ry+*rysize > gtiles->image_height)
		{
			*wysize = (int)(*wysize * ((double) (gtiles->image_height - *ry) / (double) *rysize));
			*rysize = gtiles->image_height - *ry;
		}

	}


		
}//void geo_query(struct global_mercator *gm, struct gdal_tiles *gtiles,double ulx, double uly, double lrx, double lry,	int *rx,int *ry,int *rxsize,int *rysize,int *wx, int *wy,int *wxsize, int *wysize,double querysize = 0)

/*
* Returns the maximum value of two double values
*/
///Returns the maximum value of two double values
double max_d_gtt(double a,double b)
{
	double c;
	if(a >= b)
	{
		c = a;
	}
	else
	{
		c = b;
	}
	return c;
}//double max_d_gtt(double a,double b)
/*
*Returns the minimum value of two double values
*/
///Returns the minimum value of two double values
double min_d_gtt(double a,double b)
{
	double c;
	if(a <= b)
	{
		c = a;
	}
	else
	{
		c = b;
	}
	return c;
}//double min_d_gtt(double a,double b)
/*
*Returns the maximum value
*/
///Returns the maximum value of two numbers
int gn_max_gtt(int a,int b){
	int max_value = 0;
	if(a >= b){
		max_value = a;
	}
	else
	{
		max_value = b;
	}
	return max_value;
}//int gn_max_gtt(int a,int b)
/*
*Return the minimum value
*/
///Returns the minimum value
int gn_min(int a,int b)
{
	int min_value = 0;
	if(a <= b){
		min_value = a;
	}
	else
	{
		min_value = b;
	}
	return min_value;
}//int gn_min(int a,int b)

/*
* Intitialize the gdal_tiles structure 
*/
///Intitialize the gdal_tiles structure 
void init_gdal_tiles_gtt(struct gdal_tiles *gt, char *pTMP)
{
	gt->corner_tile = 0;
	gt->current_tile_count = 0;
	gt->next_xtile_exist = 0;
	gt->next_ytile_exist = 0;
	gt->aspect_ratio = 0.0;
	gt->zoom_levels = -1;
	gt->tileSize = 256;
	gt->scaledQuery = 1;
	gt->querysize = 1024;
	gt->overviewquery = 0;

	gt->fmt = png;
	gt->ptrtile_info = NULL;
	gt->png_modified = 0;
	gt->total_tile_count = 0;
	
	gt->mbtiles_file_name = NULL;
	gt->input_filename = NULL;
	gt->dataFromBand = NULL;
	gt->tmp_folder = NULL;
	gt->os_process_id[0] = '\0';
	gt->process_id = NULL;

	int cpid;
#ifdef OS_UNIX_LINUX_BUILD	
	//char *tmpf = "/tmp";
	char *tmpf = pTMP;
	cpid = getpid();
	sprintf(gt->os_process_id,"%d",cpid);
#else
	char *tmpf = getenv("TMP");
	cpid = GetCurrentProcessId();
	sprintf(gt->os_process_id,"%d",cpid);
#endif
	if(NULL != tmpf){
		gt->tmp_folder = (char*)malloc(strlen(tmpf)+1);
		if(NULL != gt->tmp_folder){
			char fpath[1024];
			fpath[0] = '\0';
			strcpy(gt->tmp_folder,tmpf);
#ifdef OS_UNIX_LINUX_BUILD
			sprintf(fpath,"%s/mbtiles",gt->tmp_folder);
			mkdir(fpath,0777);

#else
			sprintf(fpath,"%s\\mbtiles",gt->tmp_folder);
			mkdir(fpath);
#endif
		}
		else
		{
			gt->tmp_folder = NULL;
#ifdef OS_UNIX_LINUX_BUILD
			mkdir("mbtiles",0777);
#else
			mkdir("mbtiles");
#endif
		}
	}
	else
	{
#ifdef OS_UNIX_LINUX_BUILD
		gt->tmp_folder = NULL;
		mkdir("mbtiles",0777);

#else
		gt->tmp_folder = NULL;
		mkdir("mbtiles");
#endif
	}
}//void init_gdal_tiles_gtt(struct gdal_tiles *gt)
/*
* Open the input file TIF and process
*/
///This function opens the input file in TIF format and poppulate data to
///gdal_tiles structure
int open_input_gtt(struct gdal_tiles *gt,struct global_mercator *gg){
	
	int result = MBGEN_SUCCESS;
	int raster_bands = 0;
	int tz = 0;
#ifdef MBTILES_GEN
	//Already Called in gdalwarp.cpp API
#else
	GDALAllRegister();
#endif
	gt->in_ds = GDALOpen(gt->input_filename, GA_ReadOnly);
	if(gt->in_ds != NULL)
	{
		raster_bands = GDALGetRasterCount(gt->in_ds);
		//gt->bands = raster_bands;
        gt->bands = 3;
		if(raster_bands != 0)
		{
			gt->image_height = GDALGetRasterYSize(gt->in_ds); 
			gt->image_width = GDALGetRasterXSize(gt->in_ds);
			GDALGetGeoTransform(gt->in_ds,gt->in_gt);

			GDALRasterBandH hBand = GDALGetRasterBand( gt->in_ds, 1 );
			gt->pixelDataType = GDALGetRasterDataType(hBand);
			gt->bytes_per_pixel = GDALGetDataTypeSize(gt->pixelDataType) / 8;

			gt->ominx = gt->in_gt[0];
			gt->omaxx = gt->in_gt[0]+gt->image_width*gt->in_gt[1];
			gt->omaxy = gt->in_gt[3];
			gt->ominy = gt->in_gt[3]-gt->image_height*gt->in_gt[1];
			
			gt->drvMEM = GDALGetDriverByName("MEM");
			if(NULL == gt->drvMEM)
			{
				return MBGEN_ERROR_MEM_DRV_LOAD_FAILED;
			}
			gt->drvPNG = GDALGetDriverByName("PNG");
			if(NULL == gt->drvPNG)
			{
				return MBGEN_ERROR_PNG_DRV_LOAD_FAILED;
			}
			gt->drvJPG = GDALGetDriverByName("JPEG");
			if(NULL == gt->drvJPG)
			{
				return MBGEN_ERROR_JPG_DRV_LOAD_FAILED;
			}
			for(tz=0;tz<32;tz++)
			{
				
				int tminx,tminy,tmaxx,tmaxy;
				int max_value = 0;
				
				tminx = 0;
				tminy = 0;
				tmaxx = 0;
				tmaxy = 0;

				MetersToTile(gg,gt->ominx,gt->ominy,tz,&tminx,&tminy);
				MetersToTile(gg,gt->omaxx,gt->omaxy,tz,&tmaxx,&tmaxy);
				
				tminx = gn_max_gtt(0,tminx);
				tminy = gn_max_gtt(0,tminy);

				max_value = gn_max_gtt( gt->image_width, gt->image_height);

				gt->tinfo[tz].tmaxx = tmaxx;
				gt->tinfo[tz].tmaxy = tmaxy;
				gt->tinfo[tz].tminx = tminx;
				gt->tinfo[tz].tminy = tminy;

				gt->tminz = ZoomForPixelSize(gg,gt->in_gt[1] * ((float)max_value / (float) gt->tileSize));
				gt->tmaxz = ZoomForPixelSize(gg,gt->in_gt[1]);

			}
			/*To Compute the total number of tiles */
			{
				int tzooms = 0;
				int total_tile_count = 0;
				int tminx; 
				int tminy;
				int tmaxx;
				int tmaxy;
				int querysize = 0;
				int tcount = 0;
				

				tminx = gt->tinfo[gt->tmaxz].tminx;
				tmaxx = gt->tinfo[gt->tmaxz].tmaxx;

				tminy = gt->tinfo[gt->tmaxz].tminy;
				tmaxy = gt->tinfo[gt->tmaxz].tmaxy;

								
				tcount = (1+abs(tmaxx-tminx)) * (1+abs(tmaxy-tminy));
				total_tile_count = tcount; 
				int number_of_overviews = gt->tmaxz - gt->tminz;
				int number_of_overviews_specified = 0;
				int exit_overview_tile_count = 0;
				if(gt->zoom_levels != -1){
					number_of_overviews = gt->zoom_levels - 1;
					number_of_overviews_specified = 1;
				}
				else
				{
					number_of_overviews_specified = 0;
				}
				int czoom = gt->tmaxz - 1;
				
				if(number_of_overviews != 0){
					do
					{
						tcount = 0;
						tminx = gt->tinfo[czoom].tminx;
						tmaxx = gt->tinfo[czoom].tmaxx;

						tminy = gt->tinfo[czoom].tminy;
						tmaxy = gt->tinfo[czoom].tmaxy;
						tcount = (1+abs(tmaxx-tminx)) * (1+abs(tmaxy-tminy));
						total_tile_count += tcount; 
						czoom--;
						
						number_of_overviews--;
							if(number_of_overviews == 0){
								exit_overview_tile_count = 1;
							}
					}while((czoom >= gt->tminz) && (exit_overview_tile_count == 0));
				}
				gt->total_tile_count = total_tile_count;
			}
			/* End of total number of tiles computation */
		}
		else
		{
			printf("\n No Raster bands");
			result = MBGEN_ERROR_NO_RASTERS;
		}
	}
	else
	{
		printf("\n Cannot Open [%s] by GDAL", gt->input_filename);
		result = MBGEN_ERROR_CANNOT_PROCESS_FILE;
	}
	return result;
}//int open_input_gtt(struct gdal_tiles *gt,struct global_mercator *gg)

/*
* Generate Metadata for writing into MBTiles
*/
///Generate Metadata for writing into MBTiles
void generate_metadata_gtt(struct gdal_tiles *gt,struct global_mercator *gg)
{

	double south_lat, west_lon;
	double north_lat, east_lon;

	MetersToLatLon(gg,gt->ominx,gt->ominy,&south_lat,&west_lon);
	MetersToLatLon(gg,gt->omaxx,gt->omaxy,&north_lat,&east_lon);

	south_lat = max_d_gtt(-85.05112878, south_lat);
	west_lon = max_d_gtt(-180.0,west_lon);
		
	north_lat = min_d_gtt(85.05112878, north_lat);
	east_lon = min_d_gtt(180.0,east_lon);

	gt->south_lat = south_lat;
	gt->west_lon = west_lon;
	gt->north_lat = north_lat;
	gt->east_lon = east_lon;

	int tz,tmaxx,tmaxy,tminx,tminy;

	double minLon,minLat,maxLon,maxLat;

	tz = gt->tmaxz;
	tmaxx = gt->tinfo[tz].tmaxx;
	tmaxy = gt->tinfo[tz].tmaxy;

	tminx = gt->tinfo[tz].tminx;
	tminy = gt->tinfo[tz].tminy;

	tminx = tminx+ (tmaxx - tminx)/2;
	tminy = tminy+ (tmaxy - tminy)/2;
		
	TileLatLonBounds(gg,tminx,tminy,tz,&minLat,&minLon,&maxLat,&maxLon);

	gt->center_lat = maxLat;
	gt->center_lon = maxLon;
}//generate_metadata_gtt(struct gdal_tiles *gt,struct global_mercator *gg)
/*
*	Remove distortions from the image edges
*/
///Remove distortions from the image edges
void remove_distortions(struct gdal_tiles *gt,struct global_mercator *gg, int tx,int ty,int tz, TileInfo *ptrtf)
{
	TileInfo tf = *ptrtf;
	double b_min_x, b_min_y, b_max_x, b_max_y;

	int rx1, ry1, rxsize1, rysize1, wx1, wy1, wxsize1, wysize1, querysize;
	
	querysize = gt->querysize;

	TileBounds(gg,tx,ty,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
	geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);
	
	//Clip if the request beyond the image co-ordinates
	if(rx1 + rxsize1 > gt->image_width)
	{
		rxsize1 = gt->image_width - rx1;
	}
	if(ry1 + rysize1 > gt->image_height)
	{
		rysize1 = gt->image_height - ry1;
	}
	//Following code handles the edges tiles and x's last line tiles and y's last line tiles 
	if((tx == tf.tminx) && (ty == tf.tminy)){
		//Case Bottom Left Corner
		gt->corner_tile = 1;
		if((tx+1 > tf.tmaxx)){
			//case of no neighbour tile exist
			gt->next_xtile_exist = 0;
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}
		}
		else
		{
			//case of neighbour tile exist
			gt->next_xtile_exist = 1;
			TileBounds(gg,tx+1,ty,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
			//Query the neigbour tile
			geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);

			if(rx1 + rxsize1 > gt->image_width)
			{
				rxsize1 = gt->image_width - rx1;
			}
			if(ry1 + rysize1 > gt->image_height)
			{
				rysize1 = gt->image_height - ry1;
			}

			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}

		}
	}
	else if((tx == tf.tmaxx) && (ty == tf.tminy)){
		//case bottom right corner
		gt->corner_tile = 1;
		if((tx-1 < tf.tminx)){
			//No Such tile exits
			gt->next_xtile_exist = 0;
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}
		}
		else
		{
			gt->next_xtile_exist = 1;
			TileBounds(gg,tx-1,ty,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
			//Query the neigbour tile
			geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);
			if(rx1 + rxsize1 > gt->image_width)
			{
				rxsize1 = gt->image_width - rx1;
			}
			if(ry1 + rysize1 > gt->image_height)
			{
				rysize1 = gt->image_height - ry1;
			}
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}
		}
	}
	else if((tx == tf.tmaxx) && (ty == tf.tmaxy)){
		//Case top right corner
		gt->corner_tile = 1;
		if(ty-1 > tf.tminy){
			//Neighbour tile exists
			TileBounds(gg,tx,ty-1,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
			//Query the neigbour tile
			geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);
			
			if(rx1 + rxsize1 > gt->image_width)
			{
				rxsize1 = gt->image_width - rx1;
			}
			if(ry1 + rysize1 > gt->image_height)
			{
				rysize1 = gt->image_height - ry1;
			}
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}
		}
		else
		{
			//No Neighbour tile exists
			gt->next_xtile_exist = 0;
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}

		}
	}
	else if((tx == tf.tmaxx) && (ty == tf.tminy)){
		//Case bottom right corner
		gt->corner_tile = 1;
		if(ty+1 <= tf.tmaxy){
			TileBounds(gg,tx,ty+1,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
			//Query the neigbour tile
			geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);
			if(rx1 + rxsize1 > gt->image_width)
			{
				rxsize1 = gt->image_width - rx1;
			}
			if(ry1 + rysize1 > gt->image_height)
			{
				rysize1 = gt->image_height - ry1;
			}
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}
		}
		else
		{
			gt->next_xtile_exist = 0;
			if(rxsize1 >= rysize1){
				gt->aspect_ratio = (double)rysize1/(double)rxsize1;
			}
			else
			{
				gt->aspect_ratio = (double)rxsize1/(double)rysize1;
			}
		}
	}
	else
	{
		gt->corner_tile = 0;
	}
	
}//void remove_distortions(struct gdal_tiles *gt,struct global_mercator *gg, int tx,int ty,int tz, TileInfo *ptrtf)

/*
* Generate Base tiles 
*/
///Generate Base tiles 
int generate_base_tiles_gtt(struct gdal_tiles *gt,struct global_mercator *gg)
{
	
	int result = MBGEN_SUCCESS;
	
	int tminx, tminy, tmaxx, tmaxy, querysize, tcount, ti, tz;
	int tx,ty,rx1,ry1,rxsize1,rysize1,wx1,wy1,wxsize1,wysize1;
	int bufsize = 0;
	double b_min_x, b_min_y, b_max_x, b_max_y;
	
	querysize = 0;
	tcount = 0;

	tminx = gt->tinfo[gt->tmaxz].tminx;
	tmaxx = gt->tinfo[gt->tmaxz].tmaxx;

	tminy = gt->tinfo[gt->tmaxz].tminy;
	tmaxy = gt->tinfo[gt->tmaxz].tmaxy;

	querysize = gt->querysize;
	tcount = (1+abs(tmaxx-tminx)) * (1+abs(tmaxy-tminy));

	TileInfo tf = gt->tinfo[gt->tmaxz];

	ti = 0;
	tz = gt->tmaxz;
	
	xyzzy process_tile_info;
		
	ty=tf.tmaxy;
	tx=tf.tminx;
	TileBounds(gg, tx, ty, tz, &b_min_x, &b_min_y, &b_max_x, &b_max_y);
	
	rxsize1 = (int)(abs((b_max_x - b_min_x) / gt->in_gt[1]) + 0.5);
	rysize1 = (int)(abs((b_max_y - b_min_y) / gt->in_gt[5]) + 0.5);
	
	bufsize = rxsize1 * rysize1 * gt->bands * gt->bytes_per_pixel * 4;
	
	gt->dataFromBand = (unsigned char *)malloc(bufsize);
	if(NULL == gt->dataFromBand)
	{
		return MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
	}
	int termination_status = 0;
	for(ty=tf.tmaxy;ty>tf.tminy-1;ty--)
	{
				for(tx=tf.tminx;tx<tf.tmaxx+1;tx++)
				{
					ti +=1;
					gt->current_tile_count += 1;
					TileBounds(gg,tx,ty,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
					geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,
						&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);

					process_tile_info.rx = rx1;
					process_tile_info.ry = ry1;
					process_tile_info.wx = wx1;
					process_tile_info.wy = wy1;
					process_tile_info.rxsize = rxsize1;
					process_tile_info.rysize = rysize1;
					process_tile_info.wxsize = wxsize1;
					process_tile_info.wysize = wysize1;

					remove_distortions(gt,gg,tx,ty,tz,&tf);
					double percentage = (((double)gt->current_tile_count)/((double)gt->total_tile_count)) * 0.75f;
					create_status_file_progress(gt->process_id,percentage+0.25f);
					//Check if termination requested
					termination_status = check_process_termination(gt->process_id);
					printf("%.f...",floor(((double)gt->current_tile_count)/((double)gt->total_tile_count) * 100)); 
					result = write_base_tile(gt,tx,ty,tz,&process_tile_info);
					if(result != MBGEN_SUCCESS)
					{
						return result;
					}
					
#ifdef OS_WINDOWS_BUILD
					Sleep(250);
#else
					usleep(250000);
#endif
					if(termination_status == GEOMAP_UTILS_TERM_REQUESTED)
					{
						break;
					}
				}
				if(termination_status == GEOMAP_UTILS_TERM_REQUESTED)
				{
					break;
				}
	}
	
	if(NULL != gt->dataFromBand){
		free(gt->dataFromBand);
		gt->dataFromBand = NULL;
	}
	if(termination_status == GEOMAP_UTILS_TERM_REQUESTED)
	{
		result = termination_status;
	}
	return result;	
} // int generate_base_tiles_gtt(struct gdal_tiles *gt,struct global_mercator *gg)
/*
* Set the MBTiles name 
*/
///Set the MBTiles name 
int set_mbtiles_name_gtt(struct gdal_tiles *gt,char *mbtiles_file_name)
{
	int result = MBGEN_SUCCESS;
	if((NULL != mbtiles_file_name))
	{
		gt->mbtiles_file_name = (char*)malloc(strlen(mbtiles_file_name)+1);
		if(NULL != gt->mbtiles_file_name){
			strcpy(gt->mbtiles_file_name,mbtiles_file_name);
		}
		else
		{
			result = MBGEN_ERROR_MEMMORY_ALLOCATION_FAILED;
		}
	}
	else
	{
		result = MBGEN_BAD_INPUT_PARAMETERS;
	}
	return result;
}//int set_mbtiles_name_gtt(struct gdal_tiles *gt,char *mbtiles_file_name)

/*
*	Generate Overview Tiles
*/
/**
Generate Overview Tiles
This function to be called after Generate Base tile 
*/
int generate_overview_tiles_gtt(struct gdal_tiles *gt,struct global_mercator *gg)
{
	
	int result = 0;
	int tminx, tminy, tmaxx, tmaxy, querysize, tcount;
	
	querysize = 0;
	tcount = 0;

	tminx = gt->tinfo[gt->tmaxz].tminx;
	tmaxx = gt->tinfo[gt->tmaxz].tmaxx;

	tminy = gt->tinfo[gt->tmaxz].tminy;
	tmaxy = gt->tinfo[gt->tmaxz].tmaxy;

	querysize = gt->querysize;
	tcount = (1+abs(tmaxx-tminx)) * (1+abs(tmaxy-tminy));

	int tx, ty, rx1, ry1, rxsize1, rysize1, wx1, wy1, wxsize1, wysize1, ti, tz;
	double b_min_x, b_min_y, b_max_x, b_max_y;
	
	ti = 0;
	tz = gt->tmaxz;

	xyzzy process_tile_info;
	int zoom_levels_specified = 0;

	if(gt->zoom_levels != -1){
		gt->zoom_levels = gt->zoom_levels - 1;
		zoom_levels_specified = 1;
	}
	int termination_status = 0;
	for(tz=gt->tmaxz-1;tz>=gt->tminz;tz--)
	{
		TileInfo tf = gt->tinfo[tz];

		if(zoom_levels_specified == 1)
		{
			if(gt->zoom_levels == 0){
				break;
			}
			else
			{
				gt->zoom_levels = gt->zoom_levels - 1;
			}
		}

		for(ty=tf.tmaxy;ty>tf.tminy-1;ty--)
		{
					
					for(tx=tf.tminx;tx<tf.tmaxx+1;tx++)
					{
						ti +=1;
						gt->current_tile_count += 1;
						TileBounds(gg,tx,ty,tz,&b_min_x,&b_min_y,&b_max_x,&b_max_y);
						geo_query(gg,gt,b_min_x,b_max_y,b_max_x,b_min_y,
								&rx1,&ry1,&rxsize1,&rysize1,&wx1,&wy1,&wxsize1,&wysize1,querysize);
						process_tile_info.rx = rx1;
						process_tile_info.ry = ry1;
						process_tile_info.rxsize = rxsize1;
						process_tile_info.rysize = rysize1;
						process_tile_info.wxsize = wxsize1;
						process_tile_info.wysize = wysize1;

						process_tile_info.wx = wx1;
						process_tile_info.wy = wy1;
						process_tile_info.wxsize = wxsize1;
						process_tile_info.wysize = wysize1;
						double  percentage = (((double)gt->current_tile_count)/((double)gt->total_tile_count)) * 0.75f;
						create_status_file_progress(gt->process_id,percentage + 0.25f);
						//Check if termination requested
						termination_status = check_process_termination(gt->process_id);
						printf("%.f...",floor( ((double)gt->current_tile_count)/((double)gt->total_tile_count) *100 )); 
						result = write_overview_tile(gt,tx,ty,tz,&process_tile_info);
#ifdef OS_WINDOWS_BUILD
					Sleep(250);
#else
					usleep(250000);
#endif
						if((result < 0) || (termination_status == GEOMAP_UTILS_TERM_REQUESTED) )
						{
							break;
						}
					} // End of x for loop
					if((result < 0) || (termination_status == GEOMAP_UTILS_TERM_REQUESTED) )
					{
							break;
					}
		}// End of y for loop
		if((result < 0) || (termination_status == GEOMAP_UTILS_TERM_REQUESTED) )
		{
			break;
		}
	}// End of z for loop
	if(termination_status == GEOMAP_UTILS_TERM_REQUESTED)
	{
		result = termination_status;
	}
	return result;
}//int generate_overview_tiles_gtt(struct gdal_tiles *gt,struct global_mercator *gg)
#if 0
/***************************************************************
*						process
****************************************************************/

void process(struct gdal_tiles *gt,struct global_mercator *gg){
	open_input(gt,gg);
	generate_metadata(gt,gg);
	open_mbtiles(gt);
	create_table_mbtiles(gt);
	insert_metadata_mbtiles(gt);
	generate_base_tiles(gt,gg);
	//generate_overview_tiles(gt,gg);
	close_mbtiles(gt);
}
#endif
/*
* Open the MBTiles file
*/
///Open the MBTiles file
int open_mbtiles_gtt(struct gdal_tiles *gt)
{
	int result = MBGEN_SUCCESS;
	if(SQLITE_OK != sqlite3_open(gt->mbtiles_file_name,&(gt->db2)))
	{
		result = MBGEN_ERROR_SQLITE_OPEN_FAILED;
	}
	return result;
}//int open_mbtiles_gtt(struct gdal_tiles *gt)
/*
* Create MBTiles Table 
*/
///Create Table in MBTiles file
int create_table_mbtiles_gtt(struct gdal_tiles *gt)
{
	int result = MBGEN_SUCCESS;
	if(sqlite3_exec(gt->db2,"CREATE TABLE tiles (zoom_level integer,tile_column integer,tile_row integer,tile_data blob);",
		NULL,NULL,NULL) != SQLITE_OK)
	{
			return MBGEN_ERROR_CREATE_TABLE_FAILED;
	}
	//
	if(sqlite3_exec(gt->db2,"CREATE UNIQUE INDEX tile_index on tiles (zoom_level, tile_column, tile_row);",
		NULL,NULL,NULL) != SQLITE_OK)
	{
			return MBGEN_ERROR_CREATE_TABLE_FAILED;
	}
	if(sqlite3_exec(gt->db2,"CREATE TABLE \"metadata\" (\"name\" TEXT ,\"value\" TEXT );",
		NULL,NULL,NULL) != SQLITE_OK)
	{
			return MBGEN_ERROR_CREATE_TABLE_FAILED;
	}
	if(sqlite3_exec(gt->db2,"CREATE UNIQUE INDEX \"name\" ON \"metadata\" (\"name\");",
		NULL,NULL,NULL) != SQLITE_OK)
	{
			return MBGEN_ERROR_CREATE_TABLE_FAILED;
	}
	return result;
}//int create_table_mbtiles_gtt(struct gdal_tiles *gt)
/*
Close MBTiles 
*/
///Close MBTiles
int close_mbtiles_gtt(struct gdal_tiles *gt)
{
	int result = MBGEN_SUCCESS;
	result = sqlite3_close(gt->db2);
	if(result != SQLITE_OK)
	{
		result = MBGEN_ERROR_SQLITE_CLOSE_FAILED;
	}
	return result;
}//int close_mbtiles_gtt(struct gdal_tiles *gt)

/*
*  Insert Meta data into metadata table in MBTiles
*/
///Insert Meta data into metadata table in MBTiles
int insert_metadata_mbtiles_gtt(struct gdal_tiles *gt)
{
	int result = MBGEN_SUCCESS;
	char c_szText_sql_str[MBGEN_LONG_STRING+1];
	c_szText_sql_str[0] = '\0';
	char c_szText_tem_str[MBGEN_LONG_STRING+1];
	c_szText_tem_str[0] = '\0';
	char c_szText_tem_zoom_str[MBGEN_LONG_STRING+1];
	c_szText_tem_zoom_str[0] = '\0';

	sprintf(c_szText_sql_str,"INSERT INTO metadata (name, value) VALUES (\"name\",\"%s\");","Map");
		if(sqlite3_exec(gt->db2,c_szText_sql_str,
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		sprintf(c_szText_sql_str,"INSERT INTO metadata (name, value) VALUES (\"description\",\"%s\");","");
		if(sqlite3_exec(gt->db2,c_szText_sql_str,
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		sprintf(c_szText_sql_str,"INSERT INTO metadata (name, value) VALUES (\"attribution\",\"%s\");","");
		if(sqlite3_exec(gt->db2,c_szText_sql_str,
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		sprintf(c_szText_sql_str,"INSERT INTO metadata (name, value) VALUES (\"type\",\"%s\");","baselayer");
		if(sqlite3_exec(gt->db2,c_szText_sql_str, //baselayer | overlay
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		if(sqlite3_exec(gt->db2,"INSERT INTO metadata (name, value) VALUES (\"version\",\"1\");",
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		
		if(strcmp(gt->image_type,"png") == 0)
		{
			if(sqlite3_exec(gt->db2,"INSERT INTO metadata (name, value) VALUES (\"format\",\"png\");",
				NULL,NULL,NULL) != SQLITE_OK){
					printf("\nInsert [FAILED] ...");
					return MBGEN_ERROR_INSERT_ROW_FAILED;
			}
		}
		else
		{
			if(sqlite3_exec(gt->db2,"INSERT INTO metadata (name, value) VALUES (\"format\",\"jpg\");",
				NULL,NULL,NULL) != SQLITE_OK){
					printf("\nInsert [FAILED] ...");
					return MBGEN_ERROR_INSERT_ROW_FAILED;
			}
		}
		
		int meta_data_min_zoom_levels = 0;
		if(gt->zoom_levels != -1){
			meta_data_min_zoom_levels = gt->tmaxz - (gt->zoom_levels-1);
		}
		else
		{
			meta_data_min_zoom_levels = gt->tminz;
		}
		sprintf(c_szText_tem_str,"%d",meta_data_min_zoom_levels);
		sprintf(c_szText_sql_str,"INSERT INTO metadata (name, value) VALUES (\"minzoom\",\"%s\");",c_szText_tem_str);
		if(sqlite3_exec(gt->db2,c_szText_sql_str,
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		sprintf(c_szText_tem_str,"%d",gt->tmaxz);

		sprintf(c_szText_sql_str,"INSERT INTO metadata (name, value) VALUES (\"maxzoom\",\"%s\");",c_szText_tem_str);
		if(sqlite3_exec(gt->db2,c_szText_sql_str,
			NULL,NULL,NULL) != SQLITE_OK){
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		sprintf(c_szText_tem_str,"INSERT INTO metadata (name, value) VALUES (\"bounds\",\"%.4f,%.4f,%.4f,%.4f\");",gt->west_lon,gt->south_lat,gt->east_lon,gt->north_lat);
		
		if(sqlite3_exec(gt->db2,c_szText_tem_str, 
			NULL,NULL,NULL) != SQLITE_OK)
		{
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
		sprintf(c_szText_tem_zoom_str,"%d",gt->tmaxz);
		sprintf(c_szText_tem_str,"INSERT INTO metadata (name, value) VALUES (\"center\",\"%.4f,%.4f,%s\");",gt->center_lon,gt->center_lat,c_szText_tem_zoom_str);
		
		if(sqlite3_exec(gt->db2,c_szText_tem_str, 
			NULL,NULL,NULL) != SQLITE_OK)
		{
				printf("\nInsert [FAILED] ...");
				return MBGEN_ERROR_INSERT_ROW_FAILED;
		}
	return result;
}//int insert_metadata_mbtiles_gtt(struct gdal_tiles *gt)

/*
* Function to write MBTiles 
*/
///writes a tile to the MBTile
int write_mbtiles_gtt(struct gdal_tiles *gtiles, int tz, int tx, int ty, unsigned char *ptrBlobData, unsigned int file_size)
{
	int result = MBGEN_SUCCESS;
	char sql_statement[MBGEN_LONG_STRING+1];
	sqlite3_stmt *stmt = NULL;
	char *tail;
	int sqlite_error_step = 0;

	sprintf(sql_statement,"insert into tiles (zoom_level, tile_column, tile_row, tile_data) values (%d, %d, %d, ?);", tz, tx, ty);
	sqlite3_prepare_v2(gtiles->db2, (const char*)sql_statement, strlen(sql_statement)+1, &stmt, (const char**)&tail);
	sqlite3_bind_blob(stmt, 1, (void*)ptrBlobData, file_size, SQLITE_TRANSIENT);
	sqlite_error_step = sqlite3_step(stmt);
	sqlite3_finalize(stmt);

	if(sqlite_error_step != SQLITE_DONE)
	{ 
		printf("Error message: %s\n", sqlite3_errmsg(gtiles->db2));
		return MBGEN_ERROR_INSERT_ROW_FAILED;
	}
	return result;
}//int write_mbtiles_gtt(struct gdal_tiles *gtiles, int tz, int tx, int ty, unsigned char *ptrBlobData, unsigned int file_size)

/*
* Function Removes the existing MBTiles file if exists 
*/
/// Removes an existing MBTiles
int remove_existing_mbtiles_gtt(char *mbtile_file_name)
{
	int result = MBGEN_SUCCESS;
	FILE *fp1 = fopen(mbtile_file_name,"rb");
	if(fp1 != NULL)
	{
		printf("\nMBTiles file aready exists");
		fclose(fp1);

		remove(mbtile_file_name);
		printf("\nRemoving existing MBTiles");
	}
	return result;
} //int remove_existing_mbtiles_gtt(char *mbtile_file_name)
