package org.gtmp.perl;

public class JNIStub
{
    private static native int perl_register(String clazz);
    public static native void perl_chmod(String path);

    public static int register(String clazz)
    {
	return perl_register(clazz);
    }
}
