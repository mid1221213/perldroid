package org.gtmp.perl;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.lang.reflect.Method;

public class PerlDroidProxy implements java.lang.reflect.InvocationHandler
{
    private Class clazz;
    
    public static Object newInstance(Class clazz) {
	android.util.Log.v("PerlDroidProxy", "Classe=" + clazz.getName());
	return Proxy.newProxyInstance(
				      clazz.getClassLoader(),
				      new Class[] { clazz },
				      new PerlDroidProxy(clazz)
				      );
    }
    
    private PerlDroidProxy(Class clazz) {
	this.clazz = clazz;
    }

    public Object invoke(Object proxy, Method m, Object[] args) throws Throwable
    {
	// Change PerlDroid with main class of your app on next line and uncomment it
	// return PerlDroid.perl_callback(this.clazz, m.getName(), args);
	return true; // Remove this line
    }
}
