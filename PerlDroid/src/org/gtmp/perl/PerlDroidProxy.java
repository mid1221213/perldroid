package org.gtmp.perl;

import java.lang.reflect.*;

public class PerlDroidProxy implements java.lang.reflect.InvocationHandler
{
    public static native Object perl_callback(Object obj, String m, Object[] args);
    
    private Object obj;
    
    public static Object newInstance(Object obj) {
	return java.lang.reflect.Proxy.newProxyInstance(
							obj.getClass().getClassLoader(),
							obj.getClass().getInterfaces(),
							new PerlDroidProxy(obj)
							);
    }
    
    private PerlDroidProxy(Object obj) {
          this.obj = obj;
    }

    public Object invoke(Object proxy, Method m, Object[] args) throws Throwable
    {
	return perl_callback(this.obj, m.getName(), args);
    }
}
