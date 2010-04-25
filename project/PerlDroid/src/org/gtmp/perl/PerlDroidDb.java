package org.gtmp.perl;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import java.util.Collections;
import java.util.ArrayList;
import android.util.Log;

public class PerlDroidDb {
    private static final String TAG = "PerlDroidDb"; /* used for logging */

    private static final String DATABASE_NAME = "perldroid";
    private static final int DATABASE_VERSION = 1;

    public static final String MODULE_TABLE = "module";
    public static final String KEY_MODID = "_id"; /* important for magics with adapter */
    public static final String KEY_MODNAME = "name";

    public static final String FILES_TABLE = "files";
    public static final String FKEY_MODID = "modid";
    public static final String KEY_FILENAME = "file";

    private DatabaseHelper mDbHelper;
    private SQLiteDatabase mDb;
    
    private static final String MODULE_TABLE_CREATE =
	"create table " + MODULE_TABLE + " (" 
	+ KEY_MODID + " integer primary key autoincrement, " 
	+ KEY_MODNAME + " text not null);";

    private static final String FILES_TABLE_CREATE =
	"create table " + FILES_TABLE + " (" 
	+ FKEY_MODID + " integer, " 
	+ KEY_FILENAME + " text not null);";

    private final Context mCtx;

    private static class DatabaseHelper extends SQLiteOpenHelper {

        DatabaseHelper(Context context) {
            super(context, DATABASE_NAME, null, DATABASE_VERSION);
        }

        @Override
	    public void onCreate(SQLiteDatabase db) {

            db.execSQL(MODULE_TABLE_CREATE);
            db.execSQL(FILES_TABLE_CREATE);
        }

        @Override
	    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
            Log.w(TAG, "Upgrading database from version " + oldVersion + " to "
		  + newVersion + ", which will destroy all old data");
            db.execSQL("DROP TABLE IF EXISTS " + MODULE_TABLE);
            db.execSQL("DROP TABLE IF EXISTS " + FILES_TABLE);
            onCreate(db);
        }
    }

    /**
     * Constructor - takes the context to allow the database to be
     * opened/created
     * 
     * @param ctx the Context within which to work
     */
    public PerlDroidDb(Context ctx) {
        this.mCtx = ctx;
    }

    /**
     * Open the connection database. If it cannot be opened, try to create a new
     * instance of the database. If it cannot be created, throw an exception to
     * signal the failure
     *
     * @return this (self reference, allowing this to be chained in an
     *         initialization call)
     * @throws SQLException if the database could be neither opened or created
     */
    public PerlDroidDb open() throws SQLException {
        mDbHelper = new DatabaseHelper(mCtx);
        mDb = mDbHelper.getWritableDatabase();
        return this;
    }
    
    public void close() {
        mDbHelper.close();
    }


    /**
     * Create a new module entry using the infos provided. If the module is
     * successfully created return the new rowId for that module, otherwise return
     * a -1 to indicate failure.
     */
    public long createModule(String module, ArrayList<String> files) {
        ContentValues moduleValue = new ContentValues();
        moduleValue.put(KEY_MODNAME, module);
        long modId =  mDb.replace(MODULE_TABLE, null, moduleValue);

        ContentValues fileValue = new ContentValues ();
        for (String file : files) {
            fileValue.put(KEY_FILENAME, file);
            fileValue.put(FKEY_MODID, modId);
            mDb.replace(FILES_TABLE, null, fileValue);
        }
        return modId;
    }

    /** 
     * Return a module id given it name
     */
    public Cursor getModId(String module) {
        return  mDb.query(MODULE_TABLE, new String[] {KEY_MODID},
                          KEY_MODNAME + "='" + module + "'", null, null, null, null);
    }

    /**
     * Delete the module with the given modId
     */
    public boolean deleteModule(long modId) {
        boolean ok = true;
        ok &= mDb.delete(FILES_TABLE, FKEY_MODID + "='" + Long.toString(modId) + "'", null) > 0;
        ok &= mDb.delete(MODULE_TABLE, KEY_MODID + "='" + Long.toString(modId) + "'", null) > 0;
        return ok;
    }

    /**
     * Return a Cursor over the list of all files of a module, given the modId
     */
    public Cursor fetchFiles(long modId) {
        return mDb.query(FILES_TABLE, new String[] {KEY_FILENAME},
                         FKEY_MODID + "='" + Long.toString(modId) + "'", null, null, null, null);
    }

    /**
     * Return a Cursor over the list of all modules in the database
     */
    public Cursor fetchModules() {
        return mDb.query(MODULE_TABLE, new String[] {KEY_MODID, KEY_MODNAME},
                         null, null, null, null, null);
    }

    /**
     * Return a Cursor positioned at the module that matches the given modId
     */
    public Cursor fetchModule(long modId) throws SQLException {
        Cursor mCursor = mDb.query(MODULE_TABLE, new String[] {KEY_MODID, KEY_MODNAME}, 
                                   KEY_MODID + "='" + Long.toString(modId) + "'", null, null, null, null);
        if (mCursor != null) {
            mCursor.moveToFirst();
        }
        return mCursor;
    }
}
