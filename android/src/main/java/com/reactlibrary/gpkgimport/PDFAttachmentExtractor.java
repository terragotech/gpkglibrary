package com.reactlibrary.gpkgimport;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.lowagie.text.pdf.PRStream;
import com.lowagie.text.pdf.PdfArray;
import com.lowagie.text.pdf.PdfDictionary;
import com.lowagie.text.pdf.PdfName;
import com.lowagie.text.pdf.PdfReader;

import mil.nga.geopackage.GeoPackage;


public class PDFAttachmentExtractor {

	/* File attachments inside a PDF can be of as annotations or as embedded file 
     * This class has support to handle the both annotation and embedded file
	 */

    public static void extractAttachedFiles(String inputFileWithPath,
                                            String targetpath,
                                            List<String> lstAttachedFiles) {
        try {
            PdfReader reader = new PdfReader(inputFileWithPath);
            PdfArray array;
            PdfDictionary annot;
            PdfDictionary fs;
            PdfDictionary refs;
            System.out.println("terrago reader.getNumberOfPages()"+reader.getNumberOfPages());
            for (int i = 1; i <= reader.getNumberOfPages(); i++) {
                array = reader.getPageN(i).getAsArray(PdfName.ANNOTS);
                if (array == null) continue;
                System.out.println("terrago array"+array);
                for (int j = 0; j < array.size(); j++) {
                    annot = array.getAsDict(j);
                    if (PdfName.FILEATTACHMENT.equals(annot.getAsName(PdfName.SUBTYPE))) {
                        fs = annot.getAsDict(PdfName.FS);
                        refs = fs.getAsDict(PdfName.EF);
                        Set<PdfName> sePDF = refs.getKeys();
                        Iterator<PdfName> it = sePDF.iterator();
                        int id = 0;
                        while (it.hasNext()) {
                            PdfName pdfname = it.next();
                            System.out.println("terrago pdf name"+pdfname);
                            FileOutputStream fos = null;
                            try {
                                fos = new FileOutputStream(
                                        targetpath + File.separator + fs.getAsString(pdfname).toString());
                                fos.write(PdfReader.getStreamBytes((PRStream) refs.getAsStream(pdfname)));
                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                if (fos != null) {
                                    try {
                                        fos.flush();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    try {
                                        fos.close();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                }
                            }
                            String geoPackageName = fs.getAsString(pdfname).toString();
                            System.out.println("terrago pdf exteractor"+geoPackageName);
                            lstAttachedFiles.add(targetpath + File.separator + fs.getAsString(pdfname).toString());
                            id++;
                        }
                    }
                }
            }
            reader.close();
        } catch (Exception e) {
            System.out.println("terrago error extractor "+ e);
            e.printStackTrace();
        }
    }

    public static void extractEmbeddedFiles(String inputFileWithPath, String targetpath,
                                            List<String> lstEmbeddedFiles) {
        try {
            PdfReader reader = new PdfReader(inputFileWithPath);
            PdfDictionary root = reader.getCatalog();
            PdfDictionary documentnames = root.getAsDict(PdfName.NAMES);
            System.out.println("terrago documents"+documentnames);
            if (documentnames != null) {
                PdfDictionary embeddedfiles = documentnames.getAsDict(PdfName.EMBEDDEDFILES);
                System.out.println("terrago embeddedfiles"+embeddedfiles);
                if (embeddedfiles != null) {
                    PdfArray filespecs = embeddedfiles.getAsArray(PdfName.NAMES);
                    PdfDictionary filespec;
                    PdfDictionary refs;
                    PRStream stream;
                    System.out.println("terrago embeddedfiles"+filespecs);
                    for (int i = 0; i < filespecs.size(); ) {
                        filespecs.getAsString(i++);
                        filespec = filespecs.getAsDict(i++);
                        refs = filespec.getAsDict(PdfName.EF);
                        Set<PdfName> sePDF = refs.getKeys();
                        Iterator<PdfName> it = sePDF.iterator();
                        while (it.hasNext()) {
                            PdfName key = it.next();
                            System.out.println("terrago pdf name"+key);
                            FileOutputStream fos = null;
                            try {
                                fos = new FileOutputStream(targetpath + File.separator + filespec.getAsString(key).toString());
                                stream = (PRStream) PdfReader.getPdfObject(
                                        refs.getAsIndirectObject(key));
                                fos.write(PdfReader.getStreamBytes(stream));
                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                if (fos != null) {
                                    try {
                                        fos.flush();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    try {
                                        fos.close();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                }
                            }
                            System.out.println("terrago pdf embedded"+filespec.getAsString(key).toString());
                            lstEmbeddedFiles.add(targetpath + File.separator + filespec.getAsString(key).toString());
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("terrago error embedded "+ e);
            e.printStackTrace();
        }
    }
}
