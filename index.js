
import { NativeModules } from 'react-native';
const { RNGeoPackageLibrary } = NativeModules;
var promisify = require("es6-promisify");
var _libsample = promisify(RNGeoPackageLibrary.LibrarySampleCall);
var _initGeoPackage = promisify(RNGeoPackageLibrary.initGeoPackageatPath);
var _createFeatureClass = promisify(RNGeoPackageLibrary.createFeatureclass);
var _insertFeatureRecord = promisify(RNGeoPackageLibrary.insertFeatureclassRecord);

export const GeomentryType = {
  POINT: 1,
  LINESTRING: 2,
  POLYGON: 3,
};
var GeoPackage = {
  LibrarySampleCall(testString,callback) {
    return _libsample(testString,callback)
      .catch(_error)
  },
  initGeoPackage(directoryPath,fileName, callback){
  	return _initGeoPackage(directoryPath,fileName, callback)
  		.catch(_error)
  },
  createFeatureClass(featureDict,geomentry, callback){
  	return _createFeatureClass(featureDict,geomentry, callback)
  		.catch(_error)
  },
  insertFeatureRecord(featureRecordDict,geomentry, callback){
  	return _insertFeatureRecord(featureRecordDict,geomentry, callback)
  		.catch(_error)
  }
}

export default RNGeoPackageLibrary;