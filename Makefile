export FW_DEVICE_IP=AppleTV.local
export GO_EASY_ON_ME=1
include theos/makefiles/common.mk



BUNDLE_NAME = ScreensaverSettings
ScreensaverSettings_FILES =   MLoader.m 
ScreensaverSettings_INSTALL_PATH = /Library/SettingsBundles
ScreensaverSettings_BUNDLE_EXTENSION = bundle
ScreensaverSettings_LDFLAGS = -undefined dynamic_lookup  #-L$(FW_PROJECT_DIR) -lBackRow
ScreensaverSettings_CFLAGS = -I../ATV2Includes
ScreensaverSettings_OBJ_FILES = ../SMFramework/obj/SMFramework
SUBPROJECTS = screensavertweak
include $(FW_MAKEDIR)/aggregate.mk
include $(FW_MAKEDIR)/bundle.mk

after-install::
	ssh root@$(FW_DEVICE_IP) killall Lowtide