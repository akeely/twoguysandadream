package com.twoguysandadream.dal;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;

/**
 * Created by andrew_keely on 2/17/15.
 */
public class TestUtil {

    private static final File DB_SRC = new File("src/test/resources/db");
    private static final File DB_DST = new File("build/db");

    public static void copyDatabase() throws IOException {

        FileUtils.copyDirectory(DB_SRC, DB_DST);
    }

}
