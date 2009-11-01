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

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.run);
        /* look for status view */
        status = (TextView) findViewById(R.id.status);

        String script = getIntent().getExtras().getString(Intent.EXTRA_SHORTCUT_NAME);
        status.setText(script);
        setResult(RESULT_OK);
    }
}
