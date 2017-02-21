
package com.reactlibrary;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.google.gson.Gson;
import com.reactlibrary.json.Location;

import java.io.File;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import mil.nga.geopackage.GeoPackage;
import mil.nga.geopackage.GeoPackageManager;
import mil.nga.geopackage.core.contents.Contents;
import mil.nga.geopackage.core.contents.ContentsDao;
import mil.nga.geopackage.core.contents.ContentsDataType;
import mil.nga.geopackage.core.srs.SpatialReferenceSystem;
import mil.nga.geopackage.db.GeoPackageDataType;
import mil.nga.geopackage.factory.GeoPackageFactory;
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

public class RNGeoPackageLibraryModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private GeoPackage geoPackage = null;
  private SpatialReferenceSystem srs = null;
  private ContentsDao contentsDao;
  private GeometryColumnsDao geomColumnsDao;
  private FeatureDao currentFeatureClassFeatureDAO;
  private FeatureTable currentFeatureTable;

  public RNGeoPackageLibraryModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNGeoPackageLibrary";
  }

  @ReactMethod
  public void initGeoPackageatPath(String dbPath,String dbName,Callback callback){
    try {
      srs = new SpatialReferenceSystem();
      srs.setId(4326);
      File dbFolder = new File(dbPath);
      GeoPackageManager geoPackageManager = GeoPackageFactory.getManager(reactContext);
      File dbFile = new File(dbPath+File.separator+dbName+".gpkg");
      if(dbFile.exists()){// delete db if already exist
        dbFile.delete();
      }
      geoPackageManager.createAtPath(dbName,dbFolder);// create db
      geoPackage = geoPackageManager.open(dbName);
    }catch (Exception e){
      e.printStackTrace();
    }
    callback.invoke("true");
  }

  @ReactMethod
  public void LibrarySampleCall(String testString, Callback completionCallback) {
    completionCallback.invoke(testString);
  }
  @ReactMethod
  public void createFeatureclass(ReadableMap readableMap,int geometryType,Callback callback){
    if (geoPackage != null) {
      createDefaultFeatureClass();
      List<FeatureColumn> lstFeatureColumns = new ArrayList<>();
      lstFeatureColumns.add(FeatureColumn.createPrimaryKeyColumn(0, "fid"));
      addGeometryColumn(geometryType,lstFeatureColumns);
      ReadableArray columnsArray = readableMap.getArray("Columns");
      String tableName = readableMap.getString("FeatureName");
      if(columnsArray != null){
        int size = columnsArray.size();
        for(int i=0;i<size;i++){
          ReadableMap readableMap1 = columnsArray.getMap(i);
          addField(readableMap1.getInt("columnID"),readableMap1.getString("columnName"), lstFeatureColumns);
        }
      }
      currentFeatureTable = new FeatureTable(tableName, lstFeatureColumns);
      geoPackage.createFeatureTable(currentFeatureTable);
    }
    callback.invoke("true");
  }

  @ReactMethod
  public void insertFeatureclassRecord(ReadableMap readableMap,int geometryType,Callback callback){
    try {
      String tableName = readableMap.getString("FeatureName");
      String geometry = readableMap.getString("Location");
      insertDefaultTableValue(tableName, geometryType);
      FeatureRow featureRow = currentFeatureClassFeatureDAO.newRow();
      addGeometryValuefromJson(geometry,featureRow);
      ReadableArray columnsArray = readableMap.getArray("values");
      if(columnsArray != null){
        int size = columnsArray.size();
        for(int i=0;i<size;i++){
          ReadableMap readableMap1 = columnsArray.getMap(i);
          String fieldName = readableMap1.getString("columnName");
          String fieldValue = readableMap1.getString("columnValue");
          insertValue(fieldName, fieldValue,featureRow);
        }
      }
      currentFeatureClassFeatureDAO.create(featureRow);
    }catch (Exception e){
      e.printStackTrace();
    }
    callback.invoke("true");
  }

  @ReactMethod
  public void closeGeoPackage(Callback callback){
    if(geoPackage != null){
      geoPackage.close();
    }
    callback.invoke("true");
  }

  private void createDefaultFeatureClass(){
    //Must create the gpkg_geometry_column table, as this is not created by default
    geoPackage.createGeometryColumnsTable();
    contentsDao = geoPackage.getContentsDao();
    geomColumnsDao = geoPackage.getGeometryColumnsDao();
  }

  private void addGeometryColumn(int geometryType,List<FeatureColumn> lstFeatureColumns){
    if (geometryType == 1) {
      lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.POINT, false, null));
    } else if (geometryType == 2) {
      lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.LINESTRING, false, null));
    } else if (geometryType == 3) {
      lstFeatureColumns.add(FeatureColumn.createGeometryColumn(1, "geom", GeometryType.POLYGON, false, null));
    }
  }

  private void addField(int id,String fieldName,List<FeatureColumn> lstFeatureColumns) {
    int size = lstFeatureColumns.size();
    //Note:- Current implementation supports only text
    lstFeatureColumns.add(FeatureColumn.createColumn(size, fieldName, GeoPackageDataType.TEXT, false, ""));
  }

  private void insertDefaultTableValue(String currentFeatureClassName, int geometryType){
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
  }
  private void addGeometryValuefromJson(String geoJsonString,FeatureRow featureRow) {
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

  private void insertValue(String fieldName, String fieldValue,FeatureRow featureRow) throws Exception {
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
}