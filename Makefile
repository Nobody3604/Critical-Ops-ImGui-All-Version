export THEOS=/opt/theos


ARCHS = arm64 #arm64e

DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1



include $(THEOS)/makefiles/common.mk

TWEAK_NAME = copsmm

## source files ##
KITTYMEMORY_SRC = $(wildcard KittyMemory/*.cpp)


copsmm_FRAMEWORKS =  UIKit Foundation Security QuartzCore CoreGraphics CoreText  AVFoundation Accelerate GLKit SystemConfiguration GameController

copsmm_CCFLAGS = -std=c++11 -fno-rtti -fno-exceptions -DNDEBUG
copsmm_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value

copsmm_FILES =   ImGuiDrawView.xm $(wildcard Esp/*.mm)   $(wildcard Esp/*.m) $(KITTYMEMORY_SRC) $(wildcard IMGUI/*.mm) $(wildcard IMGUI/*.cpp)

copsmm_OBJ_FILES = KittyMemory/Deps/Keystone/libs-ios/$(THEOS_CURRENT_ARCH)/libkeystone.a

#copsmm_LIBRARIES += substrate
# GO_EASY_ON_ME = 1

include $(THEOS_MAKE_PATH)/tweak.mk


