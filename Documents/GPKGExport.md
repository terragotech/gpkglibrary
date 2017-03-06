import RNGeoPackageLibrary from 'react-native-geo-package-library';
import RNFS from 'react-native-fs';

    console.log('new lib', RNGeoPackageLibrary);
    RNGeoPackageLibrary.initGeoPackageatPath(RNFS.DocumentDirectoryPath, 'test', function(e){
      //alert('gpkg created ' + e);
    });
    let dd = {
      FeatureName: 'None_Point',
      Columns: [
        {
          columnName: 'Title',
          columnID: 5,
          columnType: 'textinput'
        },
        {
          columnName: 'Note_Type',
          columnID: 6,
          columnType: 'textinput'
        }
      ]
    }
    RNGeoPackageLibrary.createFeatureclass(dd, 1, function(e) {
     // alert('Featureclass added ' + e);
    });

    let ee = {
      FeatureName: 'None_Point',
      NoteType: 'text',
      Location: '{ "type" : "Feature", "geometry" : { "type" : "Point", "coordinates" : [ -84.45433044433594, 33.91351318359375] }, "properties" : { "name" : "" }}',
      values: [
        {
          columnName: 'Title',
          columnID: 5,
          columnType: 'textinput',
          columnValue: 'Test inside'
        },
        {
          columnName: 'Note_Type',
          columnID: 6,
          columnType: 'textinput',
          columnValue: 'none'
        }
      ]
  };

    RNGeoPackageLibrary.insertFeatureclassRecord(ee, 1, function(e) {
      //alert('Featureclass Record added ' + e);
    });

    RNGeoPackageLibrary.closeGeoPackage(function(e) {
      alert('GeoPackage closed ' + e);
    });
