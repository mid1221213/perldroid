package org.gtmp.perl;

public class Snake extends android.app.Activity
{
    public void onActivityResult(int requestCode, int resultCode, android.content.Intent data)
    {
        super.onActivityResult(requestCode, resultCode, data);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onActivityResult", new Object[] { requestCode, resultCode, data }, this);
    }
    public void onChildTitleChanged(android.app.Activity childActivity, java.lang.CharSequence title)
    {
        super.onChildTitleChanged(childActivity, title);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onChildTitleChanged", new Object[] { childActivity, title }, this);
    }
    public void onConfigurationChanged(android.content.res.Configuration newConfig)
    {
        super.onConfigurationChanged(newConfig);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onConfigurationChanged", new Object[] { newConfig }, this);
    }
    public void onContentChanged()
    {
        super.onContentChanged();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onContentChanged", new Object[] {  }, this);
    }
    public boolean onContextItemSelected(android.view.MenuItem item)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onContextItemSelected(item);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onContextItemSelected", new Object[] { item }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onContextMenuClosed(android.view.Menu menu)
    {
        super.onContextMenuClosed(menu);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onContextMenuClosed", new Object[] { menu }, this);
    }
    public void onCreate(android.os.Bundle savedInstanceState)
    {
	if (savedInstanceState == null)
	    org.gtmp.perl.PerlDroid.setUp(this, org.gtmp.snake.R.class);
        super.onCreate(savedInstanceState);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreate", new Object[] { savedInstanceState }, this);
    }
    public void onCreateContextMenu(android.view.ContextMenu menu, android.view.View v, android.view.ContextMenu.ContextMenuInfo menuInfo)
    {
        super.onCreateContextMenu(menu, v, menuInfo);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreateContextMenu", new Object[] { menu, v, menuInfo }, this);
    }
    public java.lang.CharSequence onCreateDescription()
    {
        java.lang.CharSequence ret;
        Object ret_perl;
        ret = super.onCreateDescription();
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreateDescription", new Object[] {  }, this);
        if (ret_perl == null)
            return ret;
        return (java.lang.CharSequence)ret_perl;
    }
    public android.app.Dialog onCreateDialog(int id)
    {
        android.app.Dialog ret;
        Object ret_perl;
        ret = super.onCreateDialog(id);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreateDialog", new Object[] { id }, this);
        if (ret_perl == null)
            return ret;
        return (android.app.Dialog)ret_perl;
    }
    public boolean onCreateOptionsMenu(android.view.Menu menu)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onCreateOptionsMenu(menu);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreateOptionsMenu", new Object[] { menu }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public boolean onCreatePanelMenu(int featureId, android.view.Menu menu)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onCreatePanelMenu(featureId, menu);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreatePanelMenu", new Object[] { featureId, menu }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public android.view.View onCreatePanelView(int featureId)
    {
        android.view.View ret;
        Object ret_perl;
        ret = super.onCreatePanelView(featureId);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreatePanelView", new Object[] { featureId }, this);
        if (ret_perl == null)
            return ret;
        return (android.view.View)ret_perl;
    }
    public boolean onCreateThumbnail(android.graphics.Bitmap outBitmap, android.graphics.Canvas canvas)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onCreateThumbnail(outBitmap, canvas);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreateThumbnail", new Object[] { outBitmap, canvas }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public android.view.View onCreateView(java.lang.String name, android.content.Context context, android.util.AttributeSet attrs)
    {
        android.view.View ret;
        Object ret_perl;
        ret = super.onCreateView(name, context, attrs);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onCreateView", new Object[] { name, context, attrs }, this);
        if (ret_perl == null)
            return ret;
        return (android.view.View)ret_perl;
    }
    public void onDestroy()
    {
        super.onDestroy();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onDestroy", new Object[] {  }, this);
    }
    public boolean onKeyDown(int keyCode, android.view.KeyEvent event)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onKeyDown(keyCode, event);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onKeyDown", new Object[] { keyCode, event }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public boolean onKeyMultiple(int keyCode, int repeatCount, android.view.KeyEvent event)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onKeyMultiple(keyCode, repeatCount, event);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onKeyMultiple", new Object[] { keyCode, repeatCount, event }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public boolean onKeyUp(int keyCode, android.view.KeyEvent event)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onKeyUp(keyCode, event);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onKeyUp", new Object[] { keyCode, event }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onLowMemory()
    {
        super.onLowMemory();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onLowMemory", new Object[] {  }, this);
    }
    public boolean onMenuItemSelected(int featureId, android.view.MenuItem item)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onMenuItemSelected(featureId, item);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onMenuItemSelected", new Object[] { featureId, item }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public boolean onMenuOpened(int featureId, android.view.Menu menu)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onMenuOpened(featureId, menu);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onMenuOpened", new Object[] { featureId, menu }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onNewIntent(android.content.Intent intent)
    {
        super.onNewIntent(intent);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onNewIntent", new Object[] { intent }, this);
    }
    public boolean onOptionsItemSelected(android.view.MenuItem item)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onOptionsItemSelected(item);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onOptionsItemSelected", new Object[] { item }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onOptionsMenuClosed(android.view.Menu menu)
    {
        super.onOptionsMenuClosed(menu);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onOptionsMenuClosed", new Object[] { menu }, this);
    }
    public void onPanelClosed(int featureId, android.view.Menu menu)
    {
        super.onPanelClosed(featureId, menu);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPanelClosed", new Object[] { featureId, menu }, this);
    }
    public void onPause()
    {
        super.onPause();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPause", new Object[] {  }, this);
    }
    public void onPostCreate(android.os.Bundle savedInstanceState)
    {
        super.onPostCreate(savedInstanceState);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPostCreate", new Object[] { savedInstanceState }, this);
    }
    public void onPostResume()
    {
        super.onPostResume();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPostResume", new Object[] {  }, this);
    }
    public void onPrepareDialog(int id, android.app.Dialog dialog)
    {
        super.onPrepareDialog(id, dialog);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPrepareDialog", new Object[] { id, dialog }, this);
    }
    public boolean onPrepareOptionsMenu(android.view.Menu menu)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onPrepareOptionsMenu(menu);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPrepareOptionsMenu", new Object[] { menu }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public boolean onPreparePanel(int featureId, android.view.View view, android.view.Menu menu)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onPreparePanel(featureId, view, menu);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onPreparePanel", new Object[] { featureId, view, menu }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onRestart()
    {
        super.onRestart();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onRestart", new Object[] {  }, this);
    }
    public void onRestoreInstanceState(android.os.Bundle savedInstanceState)
    {
        super.onRestoreInstanceState(savedInstanceState);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onRestoreInstanceState", new Object[] { savedInstanceState }, this);
    }
    public void onResume()
    {
        super.onResume();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onResume", new Object[] {  }, this);
    }
    public java.lang.Object onRetainNonConfigurationInstance()
    {
        java.lang.Object ret;
        Object ret_perl;
        ret = super.onRetainNonConfigurationInstance();
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onRetainNonConfigurationInstance", new Object[] {  }, this);
        if (ret_perl == null)
            return ret;
        return (java.lang.Object)ret_perl;
    }
    public void onSaveInstanceState(android.os.Bundle outState)
    {
        super.onSaveInstanceState(outState);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onSaveInstanceState", new Object[] { outState }, this);
    }
    public boolean onSearchRequested()
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onSearchRequested();
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onSearchRequested", new Object[] {  }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onStart()
    {
        super.onStart();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onStart", new Object[] {  }, this);
    }
    public void onStop()
    {
        super.onStop();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onStop", new Object[] {  }, this);
    }
    public void onTitleChanged(java.lang.CharSequence title, int color)
    {
        super.onTitleChanged(title, color);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onTitleChanged", new Object[] { title, color }, this);
    }
    public boolean onTouchEvent(android.view.MotionEvent event)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onTouchEvent(event);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onTouchEvent", new Object[] { event }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public boolean onTrackballEvent(android.view.MotionEvent event)
    {
        Boolean ret;
        Object ret_perl;
        ret = super.onTrackballEvent(event);
        ret_perl = org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onTrackballEvent", new Object[] { event }, this);
        if (ret_perl == null)
            return ret;
        return ((Boolean)ret_perl).booleanValue();
    }
    public void onUserInteraction()
    {
        super.onUserInteraction();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onUserInteraction", new Object[] {  }, this);
    }
    public void onUserLeaveHint()
    {
        super.onUserLeaveHint();
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onUserLeaveHint", new Object[] {  }, this);
    }
    public void onWindowAttributesChanged(android.view.WindowManager.LayoutParams params)
    {
        super.onWindowAttributesChanged(params);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onWindowAttributesChanged", new Object[] { params }, this);
    }
    public void onWindowFocusChanged(boolean hasFocus)
    {
        super.onWindowFocusChanged(hasFocus);
        org.gtmp.perl.PerlDroid.perl_callback(this.getClass().getName(), "onWindowFocusChanged", new Object[] { hasFocus }, this);
    }
}
