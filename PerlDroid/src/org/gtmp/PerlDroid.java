package org.gtmp.perl;

import android.os.Debug;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.os.Environment;
import android.widget.TextView;
import android.widget.Toast;

public class PerlDroid extends Activity
{
    TextView pStatus;

    public static native int run_perl(int a, int b);

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

    public void Log(String string)
    {
	pStatus.setText(pStatus.getText() + "\n" + string);
    }

    /** Called when the activity is first created. */
    @Override
        public void onCreate(Bundle savedInstanceState)
    {
	super.onCreate(savedInstanceState);
	android.util.Log.v("PerlDroid", "Acting...");
	setContentView(R.layout.main);
	
	pStatus = (TextView) findViewById(R.id.StatusText);
	pStatus.setVerticalScrollBarEnabled(true);
	
	findViewById(R.id.LinearLayout).setVerticalScrollBarEnabled(true);

	int ret = run_perl(5, 4);

	Log("Result: " + ret);
    }
}
