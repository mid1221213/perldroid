LOCAL_PATH := $(call my-dir)
DUMMY := $(shell cd $(LOCAL_PATH); make -f libperl.mk 1>&2)

include $(CLEAR_VARS)

LOCAL_CFLAGS    := -I$(LOCAL_PATH)/libperl/perl-5.10.0
LOCAL_LDLIBS    := -llog -ldl
LOCAL_MODULE    := PerlDroid
LOCAL_SRC_FILES := libPerlDroid.c JNIHelp.c

include $(BUILD_SHARED_LIBRARY)
