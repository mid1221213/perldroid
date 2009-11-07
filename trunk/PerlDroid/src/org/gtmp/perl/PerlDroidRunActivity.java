package org.gtmp.perl;

import android.util.Log;
import android.content.Intent;
import android.app.Activity;
import android.view.View;
import android.widget.TextView;
import android.os.Bundle;

public class PerlDroidRunActivity extends Activity
{
    private static final String TAG = "ScriptRun";
    private static final String SCRIPTS_PATH = "scripts";

    private TextView status;

    public static native int perl_run(PerlDroidRunActivity th, String script);
    public static native Object perl_callback(Class clazz, String m, Object[] args);

    static
    {
	android.util.Log.v("PerlDroid", "Loading lib");
	try {
	    System.loadLibrary("PerlDroid");
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
        setContentView(R.layout.run);
        /* look for status view */
        status = (TextView) findViewById(R.id.status);

        String script = getIntent().getExtras().getString(Intent.EXTRA_SHORTCUT_NAME);
        status.setText("Running " + script);
	perl_run(this, getFileStreamPath(SCRIPTS_PATH).toString() + "/" + script);
    }
}
