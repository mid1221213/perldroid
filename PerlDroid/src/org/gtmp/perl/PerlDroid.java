package org.gtmp.perl;

// setprop log.redirect-stdio true

import android.os.Debug;
import android.app.Activity;
import android.util.Log;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.ScrollView;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipEntry;
import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.InputStream;
import org.apache.http.impl.client.DefaultHttpClient;
import java.net.URI;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import java.net.URISyntaxException;
import java.lang.String;
import android.os.Handler;
import android.os.Message;
import android.app.Dialog;
import android.content.DialogInterface;

public class PerlDroid extends Activity
{
    TextView pStatus;
    ScrollView pStatusSV;
    String version = "5.10.0";
    String URLPrefix = "http://dbx.gtmp.org/android/perl-core-modules-" + version;
    String coreModules[] = {
	"attributes",
	"attrs",
	"AutoLoader",
	"autouse",
	"base",
	"bigint",
	"bignum",
	"bigrat",
	"blib",
	"bytes",
	"Carp",
	"Carp::Heavy",
	"charnames",
	"Config",
	"constant",
	"diagnostics",
	"DynaLoader",
	"encoding",
	"Exporter",
	"Exporter::Heavy",
	"feature",
	"fields",
	"if",
	"integer",
	"less",
	"lib",
	"mro",
	"open",
	"ops",
	"overload",
	"re",
	"sigtrap",
	"sort",
	"strict",
	"subs",
	"threads",
	"UNIVERSAL",
	"utf8",
	"vars",
	"version",
	"warnings",
	"XSLoader",
	"PerlDroid",
    };

    public static native int run_perl(int a, int b);
    public static native android.app.AlertDialog nativeOnCreateDialog(PerlDroid th, DialogInterface.OnClickListener pl, DialogInterface.OnClickListener nl);
    public static native int perlShowDialog(PerlDroid th);
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

    public void Log(String string)
    {
	pStatus.setText(pStatus.getText() + "\n" + string);

	Handler handler = new Handler();
	Runnable AdjustScrollRunnable = new Runnable() {
		public void run() {
		    pStatusSV.scrollBy(0, pStatus.getLineHeight());
		}
	    };

	handler.post(AdjustScrollRunnable);
    }

    /** Called when the activity is first created. */
    @Override
        public void onCreate(Bundle savedInstanceState)
    {
	super.onCreate(savedInstanceState);

	android.util.Log.v("PerlDroid", "Acting...");
	setContentView(R.layout.main);
	
	pStatusSV = (ScrollView) findViewById(R.id.StatusTextSV);
	pStatus = (TextView) findViewById(R.id.StatusText);
	pStatus.setVerticalScrollBarEnabled(true);
	
	findViewById(R.id.LinearLayout).setVerticalScrollBarEnabled(true);
	
// 	int ret = run_perl(5, 4);
// 	Log("Result of 5+4: " + ret);

// 	Object[] objj = {"toto", true, new RadioGroup.LayoutParams(2, 2) };
// 	Object oret = perl_callback(new Object(), "yes", objj);
    
	if (!coreAlreadyLoaded()) {
	    Log("Downloading mandatory core modules");
	    downloadCoreModules();
	}
    }

    protected void downloadCoreModules()
    {
	final Handler handler = new Handler() {
		@Override public void handleMessage(Message msg)
		{
		    Log((java.lang.String) msg.obj);
		    if (msg.obj == "Done") {
// 			DialogInterface.OnClickListener pl = new DialogInterface.OnClickListener() {
// 				public void onClick(DialogInterface dialog, int id) {
// 				    dialog.cancel();
// 				}
// 			    };
			
// 			DialogInterface.OnClickListener nl = new DialogInterface.OnClickListener() {
// 				public void onClick(DialogInterface dialog, int id) {
// 				    PerlDroid.this.finish();
// 				}
// 			    };
			
 			perlShowDialog(PerlDroid.this);
			//int ret = run_perl(5, 4);
			//Log("Result of 5+4: " + ret);
		    }
		}
	    };
	
	Thread mBackground = new Thread(new Runnable()
	    {
		public void run()
		{
		    for (String file : coreModules) {
			Message myMsg = handler.obtainMessage();
			myMsg.obj = "Getting " + file + "...";
			handler.sendMessage(myMsg);
			downloadCoreModule(file);
		    }
		    Message myMsg = handler.obtainMessage();
		    myMsg.obj = "Done";
		    handler.sendMessage(myMsg);
		}
	    });

	mBackground.start();
    }

    protected void downloadCoreModule(String module)
    {
	InputStream in = getUrlData(URLPrefix + "/" + module + ".zip");
	unZip(in);
    }

    protected boolean coreAlreadyLoaded()
    {
	File pathPrefix = getFileStreamPath(version);
	File testFile = new File(pathPrefix + "/strict.pm");
	return testFile.exists();
    }

    protected void unZip(InputStream in)
    {
	try {
	    ZipInputStream zin = new ZipInputStream(in);

	    ZipEntry entry;
	    while ((entry = zin.getNextEntry()) != null) {
	    
		String outFilename = entry.getName();

		// Compute the file's directory and create it if needed
		File basedirectory = getFileStreamPath(version);
		String subdirectoryString = basedirectory + "/" + outFilename;
		int sep = subdirectoryString.lastIndexOf("/");
		subdirectoryString = subdirectoryString.substring(0, sep);
		File subdirectory = new File(subdirectoryString);
                subdirectory.mkdirs();

		// Open the output file
		OutputStream out = new FileOutputStream(basedirectory + "/" + outFilename);
		
		// Transfer bytes from the ZIP file to the output file
		byte[] buf = new byte[1024];
		int len;
		while ((len = zin.read(buf)) > 0) {
		    out.write(buf, 0, len);
		}
		
		out.close();
	    }
	    zin.close();
	} catch (IOException ex) {
	    String msg = ex.getMessage();
	    ex.printStackTrace();
	    android.util.Log.v("PerlDroid", "Can't unzip (msg: " + msg + ")");
	}
    }

    public InputStream getUrlData(String url) {
	try {
	    DefaultHttpClient client = new DefaultHttpClient();
	    URI uri = new URI(url);
	    HttpGet method = new HttpGet(uri);
	    HttpResponse res = client.execute(method);
	    return res.getEntity().getContent();
	} catch (ClientProtocolException e) {
	    e.printStackTrace();
	} catch (IOException e) {
	    e.printStackTrace();
	} catch (URISyntaxException e) {
	    e.printStackTrace();
	}

	return null;
    }
}
