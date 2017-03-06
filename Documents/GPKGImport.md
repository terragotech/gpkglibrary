
getgpkgFileDetails call will return
{
    importGuid:'',
	isRaster:1,
	featureClasses: [
	{
		name:'featureName1',
		guid:'',
		attributes:['attrib1','attrib2',...],
		notesCount:13
	},...
	],
	rasterLayers: ['raster1','raster2',...],
	geopackageNames: ['gpkg1', 'gpkg2',...]
	
	//If PDF with gpkg
	geopackageNames:[ {
	name:'',
	isRaster:1,
	featureClasses: [
	{
		name:'featureName1',
		guid:'',
		attributes:['attrib1','attrib2',...],
		notesCount:13
	},...
	],
	rasterLayers: ['raster1','raster2',...]
	}]
}

rasterImported event will return

{
	raster: {
		importGuid:'',
		rasterName:'',
		convertedPath:''
	}
}

noteImported event will also return

{
	note:{
		importGuid:'',
		noteType:'',
		formGuid:'',
		title:'',
		geoType:'',
		geometry:'',
		formValues: [{
			id:1,
			index:1,
			label:'',
			isAttachment:0,
			labelValue:''
			},...
		],
		edgeformTemplate:{
			name:'',
			formComponents:[
				{
					id:1,
					index:1,
					label:'',
					component:''
				},...
			]
		}
 	}
	
}



