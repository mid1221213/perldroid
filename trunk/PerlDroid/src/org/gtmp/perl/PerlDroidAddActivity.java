package org.gtmp.perl;

import android.util.Log;
import android.os.Handler;
import android.os.Message;
import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.InputStream;
import java.net.URI;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import java.net.URISyntaxException;
import java.net.UnknownHostException;
import android.app.Activity;
import android.view.View;
import android.widget.TextView;
import android.widget.Button;
import android.widget.EditText;
import android.os.Bundle;


public class PerlDroidAddActivity extends Activity
{
    private static final String TAG = "ScriptAdd";
    private static final String SCRIPTS_PATH = "scripts";

    private EditText url_edit;
    private TextView status;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.add);
        /* look for url field */
        url_edit = (EditText) findViewById(R.id.url);
        /* look for status view */
        status = (TextView) findViewById(R.id.status);
        /* look for confirm button */
        Button confirm = (Button) findViewById(R.id.confirm);

        /* set confirm callback */
        confirm.setOnClickListener(new View.OnClickListener() {
            /** Called on confirmation button press */
            public void onClick(View view) {
                downloadScript();
            }
	});
    }

    /** Download the script in background */
    protected void downloadScript()
    {
        final Handler handler = new Handler() {
                @Override public void handleMessage(Message msg)
                {
                    status.setText((String)msg.obj);
                    if (msg.obj.toString() == "Fail") {
                        setResult(RESULT_CANCELED);
                        finish();
                    } else if (msg.obj.toString() == "Done") {
                        setResult(RESULT_OK);
                        finish();
                    } else {/* wait Fail or Done */;}
                }
            };

        Thread dl_thread = new Thread(new Runnable() {
                public void run()
                {
                    String url = url_edit.getText().toString();
                    Message msg = handler.obtainMessage();
                    msg.obj = "Getting " + url + "...";
                    handler.sendMessage(msg);
                    boolean ok = download(url);

                    Message ret = handler.obtainMessage();
                    if (ok == true) {
                        ret.obj = "Done";
                    } else {
                        ret.obj = "Fail";
                    }
                    handler.sendMessage(ret);
                }
            });

        dl_thread.start();
    }

    /** download a resource and store it in default path */
    protected boolean download(String url)
    {
        InputStream in = getUrlData(url);
        if (in == null) { /* do not store anything if no input stream */
            return false;
        }
        String filename = url.substring(url.lastIndexOf("/"), url.length());
        return store(filename, in);
    }

    /** Store a stream into a file in default path */
    protected boolean store(String filename, InputStream in)
    {
        try {
            File basedir = getFileStreamPath(SCRIPTS_PATH);
            OutputStream out = new FileOutputStream(basedir + "/" + filename);
            byte[] buf = new byte[1024];
                int len;
                while ((len = in.read(buf)) > 0) {
                    out.write(buf, 0, len);
                }
            out.close();
        } catch (IOException ex) {
            return false;
        }
        return true;
    }

    /** Return a stream holding the content of http download */
    public InputStream getUrlData(String url) {
        int code;
        HttpResponse res;
        InputStream in;
        DefaultHttpClient client;
        URI uri;
        try {
            client = new DefaultHttpClient();
            uri = new URI(url);
            HttpGet method = new HttpGet(uri);
            res = client.execute(method);
            code = res.getStatusLine().getStatusCode();
            if (code != 200) { /* do not ouput a stream if not HTTP 200 OK */
                return null;
            }
            in = res.getEntity().getContent();
        } catch (Exception e) {
            return null;
        }
        return in;
    }
}
