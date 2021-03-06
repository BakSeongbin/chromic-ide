#!/bin/bash

libs="browsertestplugin.so libEGL.so libFFTEm.so libGLESv1_CM.so libase.so libagl.so libandroid_runtime.so libandroid_server.so libaudioflinger.so libc.so libc_debug.so libcameraservice.so libcorecg.so libcrypto.so libctest.so libcutils.so libdl.so libdrm1.so libdrm1_jni.so libdvm.so libemoji.so libexif.so libexpat.so libhardware.so libhardware_legacy.so libicudata.so libicui18n.so libicuuc.so libjni_latinime.so libjni_pinyinime.so liblog.so libm.so libmedia.so libmedia_jni.so libmediaplayerservice.so libnativehelper.so libnetutils.so libopencoreauthor.so libopencorecommon.so libopencoredownload.so linopencoredownloadreg.so libopencoremp4.so libopencoremp4reg.so libopencorenet_support.so libopencoreplayer.so libopencorertsp.so libopencorertspreg.so libpagemap.so libpixelflinger.so libpvasf.so libpvasfreg.so libreference-ril.so libril.so libsgl.so libskiagl.so libsonivox.so libsoundpool.so libsqlite.so libsrec_jni.so libssl.so libstdc++.so libsurfaceflinger.so libsystem_server.so libthread_db.so libui.so libutils.so libvorbisidec.so libwbxml.so libwbxml_jni.so libwebcore.so libwpa_client.so libxml2wbxml.so libz.so"

for lib in $libs
do
	~/android-sdk-linux_x86/platform-tools/adb pull /system/lib/$lib ./
done
