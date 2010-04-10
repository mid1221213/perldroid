package org.gtmp.perl;

// setprop log.redirect-stdio true

import android.os.Debug;
import android.app.Activity;
import android.util.Log;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import android.widget.ScrollView;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipEntry;
import java.util.ArrayList;
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
import android.widget.ListView;
import android.widget.ArrayAdapter;
import android.widget.Toast;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.view.Menu;
import android.view.MenuItem;
import android.view.ContextMenu;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import java.lang.Runtime;

public class PerlDroid extends Activity
{
    private ArrayAdapter<String> list_adapter;
    private static final String SCRIPTS_PATH = "scripts";
    private static final int ACTIVITY_CREATE=0;
    public static final int ADD_ID = Menu.FIRST;
    public static final int DELETE_ID = Menu.FIRST;
    public static final int SHORTCUT_ID = Menu.FIRST + 1;

    private boolean coreLoaded = false;
    private TextView pStatus;
    private ListView listView;
    private ScrollView pStatusSV;
    private String version = "5.10.0";
    private String URLPrefix = "http://dbx.gtmp.org/android/perl-core-modules-" + version;
    private String coreModules[] = {
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
	"warnings::register",
	"XSLoader",
	"PerlDroid",
    };

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
	if (!coreAlreadyLoaded()) {
	    setContentView(R.layout.init);
	    
	    pStatusSV = (ScrollView) findViewById(R.id.StatusTextSV);
	    pStatus = (TextView) findViewById(R.id.StatusText);
	    pStatus.setVerticalScrollBarEnabled(true);
	    
	    findViewById(R.id.LinearLayout).setVerticalScrollBarEnabled(true);
	    
	    Log("Downloading mandatory core modules");
	    downloadCoreModules();
	} else {
	    setupEmptyList();
	}
    }

    protected void setupEmptyList()
    {
	coreLoaded = true;
	setContentView(R.layout.main);
	listView = (ListView) findViewById(R.id.EmptyList);
    }

    protected void downloadCoreModules()
    {
	final Handler handler = new Handler() {
		@Override public void handleMessage(Message msg)
		{
		    Log((java.lang.String) msg.obj);
		    if (msg.obj == "Done") {			
			JNIStub.perl_chmod("/data/data/org.gtmp.perl/files");
			Log("Tap screen to continue.");
			pStatus.setOnClickListener(new TextView.OnClickListener() {
				public void onClick(View view) {
				    setupEmptyList();
				}
			    });
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
	File testFile = new File(pathPrefix + "/PerlDroid.pm");
	return testFile.exists();
    }

    protected void unZip(InputStream in)
    {
	File basedirectory = getFileStreamPath(version);

	try {
	    ZipInputStream zin = new ZipInputStream(in);

	    ZipEntry entry;
	    while ((entry = zin.getNextEntry()) != null) {
	    
		String outFilename = entry.getName();

		// Compute the file's directory and create it if needed
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
