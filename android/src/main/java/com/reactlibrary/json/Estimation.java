package com.reactlibrary.json;

/**
 * Created by ram on 25/10/17.
 */

public class Estimation {
    private String estimate = "";
    private String status = "";

    public String getEstimate() {
        return estimate;
    }

    public void setEstimate(String estimate) {
        this.estimate = estimate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    @Override
    public String toString() {
        return "Estimation{" +
                "estimate='" + estimate + '\'' +
                ", status='" + status + '\'' +
                '}';
    }
}
