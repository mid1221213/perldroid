package org.gtmp.perl;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.lang.reflect.Method;

public class PerlDroidProxy implements java.lang.reflect.InvocationHandler
{
    private Class clazz;
    private String pkg;
    
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
	this.pkg = null;
    }

    public static Object newInstance(Class clazz, String pkg) {
	android.util.Log.v("PerlDroidProxy", "Classe=" + clazz.getName());
	return Proxy.newProxyInstance(
				      clazz.getClassLoader(),
				      new Class[] { clazz },
				      new PerlDroidProxy(clazz, pkg)
				      );
    }
    
    private PerlDroidProxy(Class clazz, String pkg) {
	this.clazz = clazz;
	this.pkg = pkg;
    }
    public Object invoke(Object proxy, Method m, Object[] args) throws Throwable
    {
	return org.gtmp.perldialog.PerlDialog.perl_callback((this.pkg != null ? "[PKG]" + this.pkg : this.clazz.getName()), m.getName(), args);
    }
}
