package org.gtmp.perl;

// setprop log.redirect-stdio true

import android.os.Debug;
import android.util.Log;
import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import android.widget.ScrollView;
import android.widget.SimpleCursorAdapter;
import android.database.Cursor;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipEntry;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.io.Serializable;
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
import java.net.UnknownHostException;
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
    private boolean coreLoaded = false;
    private TextView pStatus;
    private ListView listView;
    private static final int DELETE_ID = Menu.FIRST;
    private PerlDroidDb mDbHelper;
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
        mDbHelper = new PerlDroidDb(this);
	android.util.Log.v("PerlDroid", "Acting...");
	if (!coreAlreadyLoaded()) {
	    setContentView(R.layout.init);
	    
	    pStatusSV = (ScrollView) findViewById(R.id.StatusTextSV);
	    pStatus = (TextView) findViewById(R.id.StatusText);
	    pStatus.setVerticalScrollBarEnabled(true);
	    findViewById(R.id.LinearLayout).setVerticalScrollBarEnabled(true);
	    Log("Downloading mandatory core modules");
	    downloadCoreModules();
	}
        // Look if we are asked to download an extra module
        Bundle extras = getIntent().getExtras();
        ArrayList<String> askmodules = extras != null ? extras.getStringArrayList("download") : null;
        if (askmodules != null) {
	    setContentView(R.layout.init);
	    pStatusSV = (ScrollView) findViewById(R.id.StatusTextSV);
	    pStatus = (TextView) findViewById(R.id.StatusText);
	    pStatus.setVerticalScrollBarEnabled(true);
	    findViewById(R.id.LinearLayout).setVerticalScrollBarEnabled(true);
            for (String module : askmodules) {
                Log("Downloading extra module " + module + "... ");
	        downloadExtraModule(module);
            }
        }
        setupList();
    }

    /** Setup the modules list */
    protected void setupList()
    {
    	coreLoaded = true;
    	setContentView(R.layout.main);
    	listView = (ListView) findViewById(R.id.ModulesList);
        mDbHelper.open();
        Cursor modulesCursor = mDbHelper.fetchModules();
        startManagingCursor(modulesCursor);
        
        // specify the fields we want to display in the list (only module name)
        String[] from = new String[]{PerlDroidDb.KEY_MODNAME};
        
        // the fields we want to bind those fields to (in this case just text1)
        int[] to = new int[]{R.id.text1};
        
        // Now create a simple cursor adapter and set it to display
        SimpleCursorAdapter modules = 
            new SimpleCursorAdapter(this, R.layout.row, modulesCursor, from, to);
        listView.setAdapter(modules);
        registerForContextMenu(listView);
        mDbHelper.close();
    }

    /** Called on long touch on an item */
    @Override
    public void onCreateContextMenu(ContextMenu menu, View v, ContextMenu.ContextMenuInfo menuInfo)
    {
        super.onCreateContextMenu(menu, v, menuInfo);
        menu.add(0, DELETE_ID, 0, "Delete module");
    }

    /** Called when a context menu item is selected */
    public boolean onContextItemSelected(MenuItem item)
    {
        String module = ((TextView)((AdapterContextMenuInfo)item.getMenuInfo()).targetView).getText().toString();
        switch (item.getItemId()) {
        case DELETE_ID:
            deleteAllFiles(module);
            mDbHelper.open();
            Cursor cur = mDbHelper.getModId(module);
            cur.moveToFirst();
            long modId = cur.getLong(cur.getColumnIndex(mDbHelper.KEY_MODID));
            cur.close();
            cur = null;
            mDbHelper.deleteModule(modId);
            mDbHelper.close();
            setupList();
            return true;
        default:
            return super.onContextItemSelected(item);
        }
    }

    /** Delete recursive if no files somewhere in */
    private void deleteRecDir(File dir) {
        if(dir.exists() && dir.isDirectory()) {
            if(dir.list().length == 0) {
                dir.delete();
                return;
            }
            File[] files = dir.listFiles();
            for(File file : files) {
                if(file.isDirectory()) {
                  deleteRecDir(file);
                  dir.delete();
                }
            }
        }
    }

    private void deleteAllFiles(String module)
    {
        String path = "";
        ArrayList<String> parents = new ArrayList<String>();
        mDbHelper.open();
        Cursor cur = mDbHelper.getModId(module);
        cur.moveToFirst();
        long modId = cur.getLong(cur.getColumnIndex(mDbHelper.KEY_MODID));
        cur.close();
        cur = null;
        cur = mDbHelper.fetchFiles(modId);
        cur.moveToFirst();
        while (!cur.isAfterLast()) {
            path = cur.getString(cur.getColumnIndex(mDbHelper.KEY_FILENAME));
            deletePath(path);
            String parent;
            try {
                parent = path.substring(0, path.lastIndexOf("/"));
            } catch (StringIndexOutOfBoundsException e) {
                parent = ""; /* module is a single file w/o parent */
            }
            if (parent.length() > 0)
                parents.add(parent);
            cur.moveToNext();
        }
        cur.close();
        cur = null;
        mDbHelper.close();
        /* now delete parent directories */
        Collections.sort(parents);
        Collections.reverse(parents);
        for (String p : parents) {
            File dir = new File(getFileStreamPath(version).toString() + "/" + p);
            deleteRecDir(dir); /* will delete if no files somewhere in */
        }
        // delete the root directory of (last) Filename if any */
        int slash = path.indexOf('/');
        if (slash != -1) {
            String root = path.substring(0, slash);
            File rootdir = new File(getFileStreamPath(version).toString() + "/" + root);
            deleteRecDir(rootdir);
        }
    }

    /** Delete a file given its relative path */
    public void deletePath(String path)
    {
        String filepath = getFileStreamPath(version).toString() + "/" + path;
        File file = new File(filepath);
        file.delete();
    }

    protected void downloadExtraModule(String module)
    {
        /* FIXME */
        Log("Done.");
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
                                    /* just continue */
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
	unZip(in, module);
    }

    protected boolean coreAlreadyLoaded()
    {
	File pathPrefix = getFileStreamPath(version);
	File testFile = new File(pathPrefix + "/PerlDroid.pm");
	return testFile.exists();
    }

    protected void unZip(InputStream in, String module)
    {
	File basedirectory = getFileStreamPath(version);
    ArrayList<String> files = new ArrayList<String>();
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
		// add the file in module's files list
                files.add(outFilename);
	    }
	    zin.close();
	} catch (IOException ex) {
	    String msg = ex.getMessage();
	    ex.printStackTrace();
	    android.util.Log.v("PerlDroid", "Can't unzip (msg: " + msg + ")");
	}
        // Do not create a database entry for a core module
        int i;
        for (i = 0; i < coreModules.length; i++)
            if (coreModules[i] == module)
                break;
//        if (i < coreModules.length)
//            return;
        // Create the module entry in database   
        mDbHelper.open();
        mDbHelper.createModule(module, files);
        mDbHelper.close();
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
