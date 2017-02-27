package com.reactlibrary;

import java.io.File;
import java.io.FilenameFilter;

/**
 * Created by ram on 24/10/16.
 */

public class UniqueFileNameFilter implements FilenameFilter {
    private String input;

    public UniqueFileNameFilter(String input) {
        this.input = input;
    }

    @Override
    public boolean accept(File dir, String filename) {
        return filename.startsWith(input);
    }
}
