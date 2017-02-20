package com.reactlibrary.json;

/**
 * Created by ram on 20/02/17.
 */

public class Geometry {
    private String type;
    //private List<List<List<Double>>> coordinates = new ArrayList<List<List<Double>>>();
    private Object coordinates = new Object();

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Object getCoordinates() {
        return coordinates;
    }

    public void setCoordinates(Object coordinates) {
        this.coordinates = coordinates;
    }

    @Override
    public String toString() {
        return "Geometry{" +
                "type='" + type + '\'' +
                ", coordinates=" + coordinates +
                '}';
    }
}
