package com.reactlibrary.utils;

import java.util.List;

import mil.nga.geopackage.features.user.FeatureDao;
import mil.nga.sf.Geometry;
import mil.nga.sf.GeometryType;
import mil.nga.sf.LineString;
import mil.nga.sf.MultiLineString;
import mil.nga.sf.MultiPolygon;
import mil.nga.sf.Point;
import mil.nga.sf.Polygon;
import mil.nga.sf.proj.Projection;
import mil.nga.sf.proj.ProjectionConstants;
import mil.nga.sf.proj.ProjectionFactory;
import mil.nga.sf.proj.ProjectionTransform;

public class GeoPackageUtil {

	private final static int GEOM_TYPE_UNSUPPORTED = 0;
	private final static int GEOM_TYPE_NONE = 1;
	public final static int GEOM_TYPE_POINT = 2;
	public final static int GEOM_TYPE_LINESTRING = 3;
	public final static int GEOM_TYPE_POLYGON = 4;

	 public final static int GEOM_TYPE_MULTIPOLYGON = 6;
	 public final static int GEOM_TYPE_MULTILINESTRING = 5;

	public final static int PROJ_STATUS_WGS_84 = 0;
	public final static int PROJ_STATUS_RE_PROJ_REQUIRED = 1;
	private final static int PROJ_STATUS_RE_PROJ_NOT_POSSIBLE = 2;
	private final static int PROJ_STATUS_NO_PROJECTION_INFO = 4;
	
	public static String exportGeomTogeoJSON(Geometry geometry){
		String geoJSON = null;
		if(geometry != null){
			StringBuilder strBuffer = new StringBuilder();
			if(getGeomType(geometry.getGeometryType()) == GeoPackageUtil.GEOM_TYPE_POINT){
				Point pt = (Point)geometry;
				strBuffer.append("{\"geometry\":{\"coordinates\":[");
				strBuffer.append(pt.getY());
				strBuffer.append(",");
				strBuffer.append(pt.getX());
				strBuffer.append("],\"type\":\"Point\"},\"properties\":{\"name\":\"\"},\"type\":\"Feature\"}");
				geoJSON = strBuffer.toString();
			}
			else if(getGeomType(geometry.getGeometryType()) == GeoPackageUtil.GEOM_TYPE_POLYGON){
				Polygon pt = (Polygon)geometry;
				strBuffer.append("{\"geometry\":{\"coordinates\":[[");
				List<LineString> lstLinString =  pt.getRings();
				int size = lstLinString.size();
				for(int i=0;i<size;i++){
					LineString lt = lstLinString.get(i);
					List<Point> lstPoint = lt.getPoints();
					int pointCount = lstPoint.size();
					for(int idx=0;idx<pointCount;idx++){
						Point pt1 = lstPoint.get(idx);
						strBuffer.append("[");
						strBuffer.append(pt1.getX());
						strBuffer.append(",");
						strBuffer.append(pt1.getY());
						strBuffer.append("]");
						if(idx < (pointCount - 1)){
							strBuffer.append(",");
						}
					}
					if(i < (size-1)){
						strBuffer.append(",");
					}
				}
				strBuffer.append("]],\"type\":\"Polygon\"},\"properties\":{\"name\":\"\"},\"type\":\"Feature\"}");
				geoJSON = strBuffer.toString();
			}
			else if(getGeomType(geometry.getGeometryType()) == GeoPackageUtil.GEOM_TYPE_LINESTRING){
				LineString lstr = (LineString)geometry;
				List<Point> lstPoint1 = lstr.getPoints();
				strBuffer.append("{\"geometry\":{\"coordinates\":[");
				int pointCount1 = lstPoint1.size();
				for(int idx=0;idx<pointCount1;idx++){
					Point pt1 = lstPoint1.get(idx);
					strBuffer.append("[");
					strBuffer.append(pt1.getX());
					strBuffer.append(",");
					strBuffer.append(pt1.getY());
					strBuffer.append("]");
					if(idx < (pointCount1 - 1)){
						strBuffer.append(",");
					}
				}
				
				strBuffer.append("],\"type\":\"LineString\"},\"properties\":null,\"type\":\"Feature\"}");
				geoJSON = strBuffer.toString();
			}else if(getGeomType(geometry.getGeometryType()) == GeoPackageUtil.GEOM_TYPE_MULTILINESTRING){
				MultiLineString multiLineString = (MultiLineString)geometry;
				List<LineString> lineStrings = multiLineString.getLineStrings();
				if(lineStrings.size() > 0){
					LineString lstr = lineStrings.get(0);
					List<Point> lstPoint1 = lstr.getPoints();
					strBuffer.append("{\"geometry\":{\"coordinates\":[");
					int pointCount1 = lstPoint1.size();
					for(int idx=0;idx<pointCount1;idx++){
						Point pt1 = lstPoint1.get(idx);
						strBuffer.append("[");
						strBuffer.append(pt1.getX());
						strBuffer.append(",");
						strBuffer.append(pt1.getY());
						strBuffer.append("]");
						if(idx < (pointCount1 - 1)){
							strBuffer.append(",");
						}
					}

					strBuffer.append("],\"type\":\"LineString\"},\"properties\":null,\"type\":\"Feature\"}");
					geoJSON = strBuffer.toString();
				}
			}else if(getGeomType(geometry.getGeometryType()) == GeoPackageUtil.GEOM_TYPE_MULTIPOLYGON){
				MultiPolygon multiPolygon = (MultiPolygon)geometry;
				List<Polygon> polygons = multiPolygon.getPolygons();
				if(polygons.size() > 0){
					Polygon pt = polygons.get(0);
					strBuffer.append("{\"geometry\":{\"coordinates\":[[");
					List<LineString> lstLinString =  pt.getRings();
					int size = lstLinString.size();
					for(int i=0;i<size;i++){
						LineString lt = lstLinString.get(i);
						List<Point> lstPoint = lt.getPoints();
						int pointCount = lstPoint.size();
						for(int idx=0;idx<pointCount;idx++){
							Point pt1 = lstPoint.get(idx);
							strBuffer.append("[");
							strBuffer.append(pt1.getX());
							strBuffer.append(",");
							strBuffer.append(pt1.getY());
							strBuffer.append("]");
							if(idx < (pointCount - 1)){
								strBuffer.append(",");
							}
						}
						if(i < (size-1)){
							strBuffer.append(",");
						}
					}
					strBuffer.append("]],\"type\":\"Polygon\"},\"properties\":{\"name\":\"\"},\"type\":\"Feature\"}");
					geoJSON = strBuffer.toString();
				}
			}
		}
		return geoJSON;
	}
	public static int getGeomType(GeometryType geomType){
		int geomTypeValue;
		
		if(geomType.equals(GeometryType.POINT))
		{
			geomTypeValue = GeoPackageUtil.GEOM_TYPE_POINT;
		}
		else if(geomType.equals(GeometryType.LINESTRING))
		{
			geomTypeValue = GeoPackageUtil.GEOM_TYPE_LINESTRING;
			
		}
		else if(geomType.equals(GeometryType.POLYGON))
		{
			geomTypeValue = GeoPackageUtil.GEOM_TYPE_POLYGON;
		}else if(geomType.equals(GeometryType.MULTILINESTRING)){
			geomTypeValue = GeoPackageUtil.GEOM_TYPE_MULTILINESTRING;
		}else if(geomType.equals(GeometryType.MULTIPOLYGON)){
			geomTypeValue = GeoPackageUtil.GEOM_TYPE_MULTIPOLYGON;
		}
		else 
		{
			geomTypeValue = GeoPackageUtil.GEOM_TYPE_UNSUPPORTED;
		}
		
		return geomTypeValue;
	}
	public static int getProjStatus(FeatureDao featureDao)
	{
		int projStatus = GeoPackageUtil.PROJ_STATUS_NO_PROJECTION_INFO;
		if(featureDao != null){
			Projection projection = featureDao.getProjection();
			if(projection != null){
					if(projection.getCode() == "4326" ){
						projStatus = GeoPackageUtil.PROJ_STATUS_WGS_84;
					}
					else
					{
						//Try to find a suitable transform
						Projection prj4326 = ProjectionFactory.getProjection(ProjectionConstants.EPSG_WORLD_GEODETIC_SYSTEM);
						ProjectionTransform projectionTransform = projection.getTransformation(prj4326);
						if(projectionTransform != null){
							projStatus = GeoPackageUtil.PROJ_STATUS_RE_PROJ_REQUIRED;
						}
						else
						{
							projStatus = GeoPackageUtil.PROJ_STATUS_RE_PROJ_NOT_POSSIBLE;
						}
						
					}
				}
			}
		return projStatus;
	}
}

