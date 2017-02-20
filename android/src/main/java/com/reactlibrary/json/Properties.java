package com.reactlibrary.json;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by ram on 20/02/17.
 */

public class Properties {
    private String name;
    private String area = "0.0";
    private String perimeter = "0.0";
    private String totalDistance = "0.0";
    private List<String> distance = new ArrayList<>();

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getArea() {
        return area;
    }

    public void setArea(String area) {
        this.area = area;
    }

    public String getPerimeter() {
        return perimeter;
    }

    public void setPerimeter(String perimeter) {
        this.perimeter = perimeter;
    }

    public String getTotalDistance() {
        return totalDistance;
    }

    public void setTotalDistance(String totalDistance) {
        this.totalDistance = totalDistance;
    }

    public List<String> getDistance() {
        return distance;
    }

    public void setDistance(List<String> distance) {
        this.distance = distance;
    }

    @Override
    public String toString() {
        return "Properties{" +
                "name='" + name + '\'' +
                ", area='" + area + '\'' +
                ", perimeter='" + perimeter + '\'' +
                ", totalDistance='" + totalDistance + '\'' +
                ", distance=" + distance +
                '}';
    }
}
