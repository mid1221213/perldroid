package org.gtmp.perl;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.lang.reflect.Method;
import java.lang.Class;
import java.lang.ClassNotFoundException;

public class PerlDroidProxy implements InvocationHandler
{
    private Class clazz;
    private String pkg;
    private Class interf;
    
    public static Object newInstance(Class clazz) {
	android.util.Log.v("PerlDroidProxy", "Classe=" + clazz.getName());
	return Proxy.newProxyInstance(
				      clazz.getClassLoader(),
				      clazz.getInterfaces(),
				      new PerlDroidProxy(clazz, null, null)
				      );
    }
    
    public static Object newInstanceInterface(String interf) {
	android.util.Log.v("PerlDroidProxy", "interface=" + interf);
	try {
	    Class c_interf = Class.forName(interf);
	    return Proxy.newProxyInstance(
					  c_interf.getClassLoader(),
					  new Class[] { c_interf },
					  new PerlDroidProxy(null, null, c_interf)
					  );
	} catch (ClassNotFoundException e) {
	    android.util.Log.v("PerlDroidProxy", "interface=" + interf + " not found");
	    return null;
	}
    }
    
    public static Object newInstance(Class clazz, String pkg) {
	android.util.Log.v("PerlDroidProxy", "Classe=" + clazz.getName());
	for (Class cls : clazz.getClasses()) {
	    android.util.Log.v("PerlDroidProxy", "GetClasses=" + cls.getName());
	}
	return Proxy.newProxyInstance(
				      clazz.getClassLoader(),
				      clazz.getInterfaces(),
				      new PerlDroidProxy(clazz, pkg, null)
				      );
    }
    
    public static Object newInstanceInterface(String interf, String pkg) {
	android.util.Log.v("PerlDroidProxy", "interface=" + interf + ", pkg=" + pkg);
	try {
	    Class c_interf = Class.forName(interf);
	    return Proxy.newProxyInstance(
					  //					  c_interf.getClassLoader(),
					  PerlDroidProxy.class.getClassLoader(),
					  new Class[] { c_interf },
					  new PerlDroidProxy(null, pkg, c_interf)
					  );
	} catch (ClassNotFoundException e) {
	    android.util.Log.v("PerlDroidProxy", "interface=" + interf + " not found");
	    return null;
	}
    }
    
    private PerlDroidProxy(Class clazz, String pkg, Class c_interf) {
	this.clazz = clazz;
	this.pkg = pkg;
	this.interf = c_interf;
    }

    public Object invoke(Object proxy, Method m, Object[] args) throws Throwable
    {
	android.util.Log.v("PerlDroidProxy", "invoking " + m.getName() + " on " + proxy.toString());
	Object obj = org.gtmp.perl.PerlDroid.perl_callback((this.pkg != null ? "[PKG]" + this.pkg : this.clazz != null ? this.clazz.getName() : this.interf.getName()), m.getName(), args, null);
	if (obj == null) {
	    return m.getDeclaringClass().getSuperclass().getMethod(m.getName(), m.getParameterTypes()).invoke(proxy, args);
	} else {
	    return obj;
	}
    }
}
