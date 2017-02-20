package com.reactlibrary.enums;

/**
 * Created by ram on 20/02/17.
 */

public enum GeometryType {
    POINT(1),LINESTRING(2),POLYGON(3);
    private int geometryId;
    GeometryType(int geometryId) {
        this.geometryId = geometryId;
    }

    public int getGeometryId() {
        return geometryId;
    }

}
