LOCAL_PATH := $(call my-dir)
PERL_PATH := $(LOCAL_PATH)/libperl/perl-5.10.1

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(PERL_PATH)
LOCAL_LDLIBS     := -llog -ldl
LOCAL_MODULE     := PerlDroid
LOCAL_SRC_FILES  := libPerlDroid.c JNIHelp.c

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(PERL_PATH)
LOCAL_LDLIBS     := -L$(LOCAL_PATH)/../libs/armeabi -L$(PERL_PATH)/ -ldl -lperl -lPerlDroid
LOCAL_MODULE     := PerlDroid_so
LOCAL_SRC_FILES  := PerlDroid.c

$(LOCAL_PATH)/PerlDroid.c: $(LOCAL_PATH)/PerlDroid.xs
	xsubpp -prototypes -output $(LOCAL_PATH)/PerlDroid.c $(LOCAL_PATH)/PerlDroid.xs

include $(BUILD_SHARED_LIBRARY)
