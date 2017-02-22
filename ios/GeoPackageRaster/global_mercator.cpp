#include "config.h"
#include <stdio.h>
#include <math.h>
#include "global_mercator.h"
int init_global_mercator(struct global_mercator *gm){
	gm->PI = 3.14159265359;
	gm->tileSize = 256;
	gm->originShift = 2 * gm->PI * 6378137 / 2.0;
	gm->MAXZOOMLEVEL = 32;
	gm->initialResolution = 2 * gm->PI * 6378137 / gm->tileSize;
	return 0;
}
void LatLonToMeters(struct global_mercator *gm, double lat, double lon, double *mx, double *my){
	if((mx != NULL) && (my != NULL)){
		
		*mx = lon * gm->originShift / 180.0;
		*my = log(tan((90 + lat ) * gm->PI / 360.0 )) / (gm->PI / 180.0); 
		*my = *my * gm->originShift / 180.0;
	}
}
void MetersToLatLon(struct global_mercator *gm,double mx, double my,double *lat, double *lon)
{
	
	if((lat != NULL) && (lon != NULL))
	{
		*lon = (mx / gm->originShift) * 180.0;
		*lat = (my / gm->originShift) * 180.0;
		*lat = (180.0 / gm->PI) * ( 2 * atan(exp(*lat * gm->PI / 180.0)) - (gm->PI / 2.0));
	}
}
void getResoultion(struct global_mercator *gm, double zoom, double *resolution_value)
{
	*resolution_value  = gm->initialResolution / pow(2.0,zoom);	
}

void PixelToMeters(struct global_mercator *gm, double px, double py, double zoom,double *mx,double *my)
{
	if((mx != NULL) && (my != NULL))
	{
		double resoultion_value=0;
		getResoultion(gm,zoom,&resoultion_value);

		*mx = px * resoultion_value - gm->originShift;
		*my = py * resoultion_value - gm->originShift;
	}
}
void MetersToPixel(struct global_mercator *gm, double mx, double my, double zoom, double *px, double *py){
	if((px != NULL) && (py != NULL)){
		double resolution_value;
		getResoultion(gm,zoom,&resolution_value);
		*px = (mx + gm->originShift) / resolution_value;
		*py = (my + gm->originShift) / resolution_value;
	}
}
void pixelsToTiles(struct global_mercator *gm, double px, double py, int *tx, int *ty)
{
	if((tx != NULL) && (ty != NULL))
	{
		*tx = (int)ceil(px / (gm->tileSize)) - 1.0;
		*ty = (int)ceil(py / (gm->tileSize)) - 1.0;
	}
}

void PixelToRaster(struct global_mercator *gm,double px, double py,double zoom, double *rpx, double *rpy)
{
	if((rpx != NULL) && (rpy != NULL) )
	{
		double mapSize;
		int i_zoom = zoom;
		int i_tileSize = gm->tileSize;
		mapSize = i_tileSize << i_zoom;
		*rpx = px;
		*rpy = mapSize - py;
	}	
}
void MetersToTile(struct global_mercator *gm,double mx, double my, double zoom, int *rpx, int *rpy)
{
	double px,py;
	/*int tx,ty;*/
	MetersToPixel(gm,mx,my,zoom,&px,&py);
	pixelsToTiles(gm,px,py,rpx,rpy);
}
void TileBounds(struct global_mercator *gm, int tx,int ty, double zoom, double *minx, double *miny, double *maxx, double *maxy)
{
	PixelToMeters(gm, tx * gm->tileSize, ty * gm->tileSize,zoom, minx, miny);
	PixelToMeters(gm,(tx+1) * gm->tileSize, (ty+1)*gm->tileSize,zoom,maxx,maxy); 

}
void TileLatLonBounds(struct global_mercator *gm, int tx, int ty, double zoom, double *minLat, double *minLon, double *maxLat, double *maxLon)
{
		double minx,miny,maxx,maxy;
		TileBounds(gm,tx,ty,zoom,&minx,&miny,&maxx,&maxy);
		MetersToLatLon(gm,minx,miny,minLat,minLon);
		MetersToLatLon(gm,maxx,maxy,maxLat,maxLon);
}
int ZoomForPixelSize(struct global_mercator *gm,double pixelSize )
{
	
		int i = 0;
		int result = 0;
		for(i=0;i<gm->MAXZOOMLEVEL;i++)
		{
			double resolution_size = 0;
			getResoultion(gm,i,&resolution_size);
			if(pixelSize > resolution_size)
			{
				if(i != 0){
					result = i-1;
					return(result);
				}	
				else
				{
					result = 0;
					return(result);
				}
			}
		}
    return 0;
}
