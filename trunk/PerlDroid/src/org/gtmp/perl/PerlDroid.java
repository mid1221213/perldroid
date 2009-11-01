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

public class PerlDroid extends Activity
{
    private ArrayAdapter<String> list_adapter;
    private static final String SCRIPTS_PATH = "scripts";
    private static final int ACTIVITY_CREATE=0;
    public static final int ADD_ID = Menu.FIRST;
    public static final int DELETE_ID = Menu.FIRST;
    public static final int SHORTCUT_ID = Menu.FIRST + 1;
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
	if (!coreAlreadyLoaded()) {
	    setContentView(R.layout.init);
	    
	    pStatusSV = (ScrollView) findViewById(R.id.StatusTextSV);
	    pStatus = (TextView) findViewById(R.id.StatusText);
	    pStatus.setVerticalScrollBarEnabled(true);
	    
	    findViewById(R.id.LinearLayout).setVerticalScrollBarEnabled(true);
	    
	    Log("Downloading mandatory core modules");
	    downloadCoreModules();
	}
    }

    protected void setupScriptList()
    {
	setContentView(R.layout.main);
	listView = (ListView) findViewById(R.id.ScriptList);
        ArrayList<String> array = new ArrayList<String>();
        list_adapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, array);
        fillData();
        registerForContextMenu(listView);

	/** Called when a list item is clicked */
	listView.setOnItemClickListener(new ListView.OnItemClickListener() {
		public void onItemClick(AdapterView l, View v, int position, long id) {
		    String scriptname = ((TextView)v).getText().toString();
		    // String scriptpath = getFileStreamPath(SCRIPTS_PATH).toString() +  "/" + scriptname;
		    Intent i = new Intent(PerlDroid.this, PerlDroidRunActivity.class);
		    i.putExtra(Intent.EXTRA_SHORTCUT_NAME, scriptname);
		    startActivityForResult(i, ACTIVITY_CREATE);
		}
	    });
	
    }

    /** Load scripts from default directory. */
    private void fillData()
    {
        File basedir = getFileStreamPath(SCRIPTS_PATH);
        if (!basedir.exists())
		basedir.mkdir();
        String [] files = basedir.list();
        if (files != null) {
            list_adapter.clear();
            for (String file : files) {
                list_adapter.add(file);
            }
            listView.setAdapter(list_adapter);
        }
    }

    /** Called when the Menu button is pressed */
    @Override
    public boolean onCreateOptionsMenu(Menu menu)
    {
        boolean result = super.onCreateOptionsMenu(menu);
        menu.add(0, ADD_ID, 0, R.string.menu_add);
        return result;
    }

    /** Called on long touch on an item */
    @Override
    public void onCreateContextMenu(ContextMenu menu, View v, ContextMenu.ContextMenuInfo menuInfo)
    {
        super.onCreateContextMenu(menu, v, menuInfo);
        menu.add(0, DELETE_ID, 0, R.string.ctx_delete);
        menu.add(0, SHORTCUT_ID, 0, R.string.ctx_shortcut);
    }

    /** Called when a context menu item is selected */
    public boolean onContextItemSelected(MenuItem item) {
        AdapterContextMenuInfo info = (AdapterContextMenuInfo) item.getMenuInfo();
        switch (item.getItemId()) {
        case DELETE_ID:
            deleteScript(info);
            return true;
        case SHORTCUT_ID:
            shortcutScript(info);
            return true;
        default:
            return super.onContextItemSelected(item);
        }
    }

    /** delete a script given its menuitem */
    private void deleteScript(AdapterContextMenuInfo info)
    {
        String filename = ((TextView)info.targetView).getText().toString();
        String filepath = getFileStreamPath(SCRIPTS_PATH).toString() + "/" + filename;
        File file = new File(filepath);
        file.delete();
        fillData();
    }

    /** Install shortcut */
    private void shortcutScript(AdapterContextMenuInfo info)
    {
        String filename = ((TextView)info.targetView).getText().toString();
        // String filepath = getFileStreamPath(SCRIPTS_PATH).toString() + "/" + filename;
	Intent shortcut = new Intent(this, PerlDroidRunActivity.class);
        shortcut.putExtra(Intent.EXTRA_SHORTCUT_NAME, filename);
	Intent install = new Intent();
        install.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcut);
        install.putExtra(Intent.EXTRA_SHORTCUT_NAME, filename);
	Bitmap bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.icon, null);
        install.putExtra(Intent.EXTRA_SHORTCUT_ICON, bitmap);
        install.setAction("com.android.launcher.action.INSTALL_SHORTCUT");
        sendBroadcast(install);
        Toast.makeText(this, R.string.shortcut_created, Toast.LENGTH_SHORT).show();

    }

    /** Called when the item is selected from the menu */
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case ADD_ID:
            return launch_download_activity();
        }
        /* default: */
        return super.onOptionsItemSelected(item);
    }

    /** Launch the download activity */
    private boolean launch_download_activity()
    {
        Intent  i = new Intent(this, PerlDroidAddActivity.class);
        startActivityForResult(i, ACTIVITY_CREATE);
        return true;
    }

    /** Called when the child activity is returning */
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent intent) {
        super.onActivityResult(requestCode, resultCode, intent);
        /* FIXME: do something if resultCode is bad */
        fillData();
    }

    protected void downloadCoreModules()
    {
	final Handler handler = new Handler() {
		@Override public void handleMessage(Message msg)
		{
		    Log((java.lang.String) msg.obj);
		    if (msg.obj == "Done") {			
			Log("Tap screen to continue.");
			pStatus.setOnClickListener(new TextView.OnClickListener() {
				public void onClick(View view) {
				    setupScriptList();
				}
			    });
 			//perlShowDialog(PerlDroid.this);
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
	File testFile = new File(pathPrefix + "/PerlDroid.pm");
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
