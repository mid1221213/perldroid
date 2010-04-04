package org.gtmp.perldialog;

import android.util.Log;
import android.app.Activity;
import android.os.Bundle;
import android.content.Context;
import android.content.res.AssetManager;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.File;

public class PerlDialog extends Activity
{
    public static native int perl_run(Context th, String script);
    public static native Object perl_callback(Class clazz, String m, Object[] args);
    public static final String SCRIPT_NAME = "PerlDialog.pl";

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

	android.util.Log.v("PerlDroid", "Launching script");
	perl_run(this, path + "/" + SCRIPT_NAME);
    }
}
