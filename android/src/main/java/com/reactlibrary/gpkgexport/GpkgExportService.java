package com.reactlibrary.gpkgexport;

import android.content.Context;
import com.google.gson.Gson;
import com.reactlibrary.json.Location;

import java.util.Date;
import java.util.List;

import mil.nga.geopackage.GeoPackage;
import mil.nga.geopackage.core.contents.Contents;
import mil.nga.geopackage.core.contents.ContentsDao;
import mil.nga.geopackage.core.contents.ContentsDataType;
import mil.nga.geopackage.core.srs.SpatialReferenceSystem;
import mil.nga.geopackage.db.GeoPackageDataType;
import mil.nga.geopackage.features.columns.GeometryColumns;
import mil.nga.geopackage.features.columns.GeometryColumnsDao;
import mil.nga.geopackage.features.user.FeatureColumn;
import mil.nga.geopackage.features.user.FeatureDao;
import mil.nga.geopackage.features.user.FeatureRow;
import mil.nga.geopackage.features.user.FeatureTable;
import mil.nga.geopackage.geom.GeoPackageGeometryData;
import mil.nga.geopackage.schema.TableColumnKey;
import mil.nga.wkb.geom.Geometry;
import mil.nga.wkb.geom.GeometryType;
import mil.nga.wkb.geom.LineString;
import mil.nga.wkb.geom.Point;
import mil.nga.wkb.geom.Polygon;

/**
 * Created by ram on 27/02/17.
 */

public class GpkgExportService {
    private Context context = null;
    private ContentsDao contentsDao;
    private GeometryColumnsDao geomColumnsDao;
    private GeoPackage geoPackage = null;


    public GpkgExportService(Context context) {
        this.context = context;
    }

    public void createDefaultFeatureClass(){
        //Must create the gpkg_geometry_column table, as this is not created by default
        geoPackage.createGeometryColumnsTable();
        contentsDao = geoPackage.getContentsDao();
        geomColumnsDao = geoPackage.getGeometryColumnsDao();
    }

    public void addGeometryColumn(int geometryType,List<FeatureColumn> lstFeatureColumns){
        if (geometryType == 1) {
            lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.POINT, false, null));
        } else if (geometryType == 2) {
            lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.LINESTRING, false, null));
        } else if (geometryType == 3) {
            lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.POLYGON, false, null));
        }
    }

    public void addField(String fieldName,List<FeatureColumn> lstFeatureColumns) {
        int size = lstFeatureColumns.size();
        //Note:- Current implementation supports only text
        lstFeatureColumns.add(FeatureColumn.createColumn(size, fieldName, GeoPackageDataType.TEXT, false, ""));
    }

    public FeatureDao insertDefaultTableValue(String currentFeatureClassName, int geometryType, SpatialReferenceSystem srs){
        FeatureDao currentFeatureClassFeatureDAO = null;
        try {
            //Create entry in the gpkg_geom_columns
            GeometryColumns currentFeatureClassGeomColums = new GeometryColumns();
            TableColumnKey id = new TableColumnKey(currentFeatureClassName, "geom");
            currentFeatureClassGeomColums.setId(id);

            currentFeatureClassGeomColums.setColumnName("geom");
            switch (geometryType) {
                case 0:
                    currentFeatureClassGeomColums.setGeometryType(GeometryType.POINT);
                    break;
                case 1:
                    currentFeatureClassGeomColums.setGeometryType(GeometryType.LINESTRING);
                    break;
                case 2:
                    currentFeatureClassGeomColums.setGeometryType(GeometryType.POLYGON);
                    break;
            }
            currentFeatureClassGeomColums.setSrs(srs);
            currentFeatureClassGeomColums.setM((byte) 0);
            currentFeatureClassGeomColums.setZ((byte) 0);

            Contents geomContent = new Contents();
            geomContent.setTableName(currentFeatureClassName);
            geomContent.setDataType(ContentsDataType.FEATURES);
            currentFeatureClassGeomColums.setContents(geomContent);
            geomColumnsDao.create(currentFeatureClassGeomColums);

            //Now add entry in the contents table gpkg_contents
            Contents content = new Contents();
            content.setTableName(currentFeatureClassName);
            content.setDataType(ContentsDataType.FEATURES);
            content.setIdentifier(currentFeatureClassName);
            content.setDescription("");
            //Sets the current date i.e. the last modified
            content.setLastChange(new Date());

            content.setMinX(0.0);
            content.setMinY(0.0);
            content.setMaxX(0.0);
            content.setMaxY(0.0);

            content.setSrs(srs);
            contentsDao.create(content);
            currentFeatureClassFeatureDAO = geoPackage.getFeatureDao(currentFeatureClassGeomColums);
        }catch (Exception e){
            e.printStackTrace();

        }
        return currentFeatureClassFeatureDAO;
    }
    public void addGeometryValuefromJson(String geoJsonString, FeatureRow featureRow, FeatureTable currentFeatureTable,FeatureDao currentFeatureClassFeatureDAO) {
        for (FeatureColumn column : currentFeatureTable.getColumns()) {
            if (!column.isPrimaryKey()) {
                if (!column.isGeometry()) {
                    Geometry geometry = getGeometryType(geoJsonString);
                    if (geometry != null) {
                        long srsid = currentFeatureClassFeatureDAO.getGeometryColumns().getSrsId();
                        GeoPackageGeometryData geometryData = new GeoPackageGeometryData(
                                srsid);
                        geometryData.setGeometry(geometry);
                        featureRow.setGeometry(geometryData);
                    }
                }
            }
        }
    }

    private Geometry getGeometryType(String geoJson) {
        if (geoJson != null) {
            Gson gson = new Gson();
            Location location = gson.fromJson(geoJson, Location.class);
            if (location != null) {
                String geometryType = location.getGeometry().getType();
                switch (geometryType) {
                    case "LineString":
                        List<List<Double>> coOrdinates = (List) location.getGeometry().getCoordinates();
                        LineString lineString = new LineString(false, false);
                        Point point;
                        for (List<Double> doubleList : coOrdinates) {
                            point = new Point(doubleList.get(0), doubleList.get(1));
                            lineString.addPoint(point);
                        }
                        return lineString;
                    case "Point":
                        List<Double> pointList = (List) location.getGeometry().getCoordinates();
                        return new Point(pointList.get(1), pointList.get(0));
                    case "Polygon":
                        List<List<List<Double>>> polygonCoordinates = (List) location.getGeometry().getCoordinates();
                        Point polygonPoint;
                        Polygon polygon = new Polygon(false, false);
                        for (List<Double> doubleList : polygonCoordinates.get(0)) {
                            polygonPoint = new Point(doubleList.get(0), doubleList.get(1));
                            LineString lineString1=new LineString(false,false);
                            lineString1.addPoint(polygonPoint);
                            polygon.addRing(lineString1);
                        }
                        return polygon;
                    default:
                        return null;
                }
            }
        }
        return null;
    }

    public void insertValue(String fieldName, String fieldValue,FeatureRow featureRow,FeatureTable currentFeatureTable) throws Exception {
        boolean fieldFound = false;
        for (FeatureColumn column : currentFeatureTable.getColumns()) {
            if (!column.isPrimaryKey()) {
                if (!column.isGeometry()) {
                    if (column.getName().equals(fieldName)) {
                        fieldFound = true;
                        featureRow.setValue(column.getName(), fieldValue);
                        break;
                    }
                }
            }
        }
        if (!fieldFound) {
            throw new Exception("Unknow field name");
        }
    }

    public GeoPackage getGeoPackage() {
        return geoPackage;
    }

    public void setGeoPackage(GeoPackage geoPackage) {
        this.geoPackage = geoPackage;
    }
}
