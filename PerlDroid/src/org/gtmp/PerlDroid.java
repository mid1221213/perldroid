package org.gtmp.perl;

import android.os.Debug;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;
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

public class PerlDroid extends Activity
{
    TextView pStatus;
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
	"charnames",
	"Config",
	"constant",
	"diagnostics",
	"DynaLoader",
	"encoding",
	"Exporter",
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
    };

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

	Log("Result of 5+4: " + ret);

	if (ret == 9 && !coreAlreadyLoaded()) {
	    Log("Downloading mandatory core modules");
	    downloadCoreModules();
	}
    }

    protected void downloadCoreModules()
    {
	for (String file : coreModules) {
	    downloadCoreModule(file);
	}
    }

    protected void downloadCoreModule(String module)
    {
	Log("Getting " + module);
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
	    
		String outFilename = entry.getName();;

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
	    Log("Can't unzip (msg: " + msg + ")");
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
