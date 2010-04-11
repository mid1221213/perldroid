package org.gtmp.perldialog;

import android.util.Log;
import android.app.Activity;
import android.os.Bundle;
import android.content.Context;
import android.content.res.AssetManager;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.Class;
import java.io.FileWriter;

public class PerlDialog extends Activity
{
    public static native int perl_run(Object thiz, String clazz, String script, String path);
    public static native Object perl_callback(Class clazz, String m, Object[] args);
    public static final String SCRIPT_NAME = "PerlDialog.pl";
    public static final String R_NAME = "R.pm";

    static
    {
	android.util.Log.v("PerlDroid", "Loading lib");
	try {
	    System.load("/data/data/org.gtmp.perl/lib/libPerlDroid.so");
	    org.gtmp.perl.JNIStub.register("org.gtmp.perldialog.PerlDialog");
	    android.util.Log.v("PerlDroid", "Successfully loaded JNI layer");
	} catch (UnsatisfiedLinkError ex) {
	    String msg = ex.getMessage();
	    android.util.Log.v("PerlDroid", "Not loaded JNI layer (msg: " + msg + ")");
	}
    }

    /** Called when the activity is first created. */
    @Override
	public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

	android.util.Log.v("PerlDroid", "Installing script");
	File path = getFileStreamPath("");

	try {
	    InputStream in = this.getAssets().open(SCRIPT_NAME);
	    FileOutputStream out = new FileOutputStream(path + "/" + SCRIPT_NAME);
	    
	    // Transfer bytes from the ZIP file to the output file
	    byte[] buf = new byte[1024];
	    int len;
	    while ((len = in.read(buf)) > 0) {
		out.write(buf, 0, len);
	    }
	    
	    in.close();
	    out.close();
	} catch (Exception ex) {
	}

	try {
	    FileWriter r_out = new FileWriter(path + "/" + R_NAME);
	    r_out.append("package R;\nrequire Exporter;\nour @ISA = qw/Exporter/;\nour @EXPORT = qw/%R/;\nour %R = (\n");
	    
	    for (Class c : R.class.getDeclaredClasses()) {
		String cn = c.getName();
		r_out.append("  '" + cn.substring(cn.lastIndexOf('$') + 1) + "' => {\n");
		for (Field field : c.getFields()) {
		    long l = field.getLong(field);
		    String fn = field.getName();
		    r_out.append("    '" + fn.substring(fn.lastIndexOf('$') + 1) + "' => 0x" + java.lang.Long.toHexString(l) + ",\n");
		}
		r_out.append("  },\n");
	    }
	    
	    r_out.append(");\n1;\n");
	    r_out.close();
	} catch (Exception ex) {
	}


	android.util.Log.v("PerlDroid", "Launching script: " + path + "/" + SCRIPT_NAME + " (" + this.getClass().getSuperclass().getName() + ")");
	perl_run(this, this.getClass().getSuperclass().getName(), path + "/" + SCRIPT_NAME, path.toString());
    }
}
