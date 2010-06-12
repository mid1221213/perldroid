package org.gtmp.perl;

import android.util.Log;
import android.app.Activity;
import android.os.Bundle;
import android.content.ContextWrapper;
import android.content.res.AssetManager;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.Class;
import java.io.FileWriter;

public class PerlDroid
{
//     private static native int perl_register(String clazz);
    private static native int perl_run(String path);
    public static native Object perl_callback(String clazzName, String m, Object[] args, Object thiz);
    public static native void perl_chmod(String path);
    public static final String R_NAME = "R.pm";

    static
    {
	android.util.Log.v("PerlDroid", "Loading lib");
	try {
	    System.load("/data/data/org.gtmp.perl/lib/libPerlDroid.so");
	    android.util.Log.v("PerlDroid", "Successfully loaded JNI layer");
	} catch (UnsatisfiedLinkError ex) {
	    String msg = ex.getMessage();
	    android.util.Log.v("PerlDroid", "Not loaded JNI layer (msg: " + msg + ")");
	}

    }

    public static void setUp(ContextWrapper thiz, Class R) {
	android.util.Log.v("PerlDroid", "Installing modules");
	File path = thiz.getFileStreamPath("");
	try {
	    AssetManager amgr = thiz.getAssets();
	    String[] files = amgr.list("");
		
	    for (String file : files) {
		InputStream in = amgr.open(file);
		FileOutputStream out = new FileOutputStream(path + "/" + file);
		    
		// Transfer bytes from the ZIP file to the output file
		byte[] buf = new byte[1024];
		int len;
		while ((len = in.read(buf)) > 0) {
		    out.write(buf, 0, len);
		}
		    
		in.close();
		out.close();
	    }
	} catch (Exception ex) {
	}
		
	try {
	    FileWriter r_out = new FileWriter(path + "/" + R_NAME);
	    r_out.append("package R;\nrequire Exporter;\nour @ISA = qw/Exporter/;\nour @EXPORT = qw/%R/;\nour %R = (\n");
		
	    for (Class c : R.getDeclaredClasses()) {
		String cn = c.getName();
		r_out.append("  '" + cn.substring(cn.lastIndexOf('$') + 1) + "' => {\n");
		for (Field field : c.getFields()) {
		    String fn = field.getName();
		    try {
			long l = field.getLong(field);
			r_out.append("    '" + fn.substring(fn.lastIndexOf('$') + 1) + "' => 0x" + java.lang.Long.toHexString(l) + ",\n");
		    } catch (Exception exl) {
			android.util.Log.v("PerlDroid", "R.pm: ignoring " + fn + " (msg: " + exl.getMessage() + ")");
		    }
		}
		r_out.append("  },\n");
	    }
		
	    r_out.append(");\n1;\n");
	    r_out.close();
	} catch (Exception ex) {
	    android.util.Log.v("PerlDroid", "Not generated R.pm (msg: " + ex.getMessage() + ")");
	}
	    
	android.util.Log.v("PerlDroid", "Initializing interpreter");
	perl_run(path.toString());
    }
}
