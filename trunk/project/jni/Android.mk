LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := PerlDroid
LOCAL_SRC_FILES := libPerlDroid.c

include $(BUILD_SHARED_LIBRARY)
