Rojo_Windows_RELEASE_URL = https://github.com/rojo-rbx/rojo/releases/download/v0.5.4/rojo-0.5.4-win64.zip
Rojo_Linux_RELEASE_URL   = https://github.com/rojo-rbx/rojo/releases/download/v0.5.4/rojo-0.5.4-linux.zip
Rojo_MacOS_RELEASE_URL   = https://github.com/rojo-rbx/rojo/releases/download/v0.5.4/rojo-0.5.4-macos.zip

ROJO_VERSION = 0.5.4

TestScriptName = ExampleOfUse.server.lua
TestScriptDir = ./TestPlaceScript

ToolsDir = ./Tools

SrcDir = ./src

BuildName = build.rbxlx
TestBuildName = test.rbxlx

.PHONY: download_deps build clean test

##########################################################

DETECTED_OS =
ROJO =

ifeq ($(OS),Windows_NT)
	DETECTED_OS = Windows

	ROJO = $(ToolsDir)/Windows/rojo-$(ROJO_VERSION).exe
else
	UNAME_S := $(shell uname -s)

	ifeq ($(UNAME_S),Linux)
		DETECTED_OS = Linux
	endif

	ifeq ($(UNAME_S),Darwin)
		DETECTED_OS = MacOS
	endif

	ROJO = $(ToolsDir)/$(DETECTED_OS)/rojo-$(ROJO_VERSION)
endif

##########################################################

build: download_deps
	rm -f $(BuildName)
	$(ROJO) build -o $(BuildName)

test: download_deps
	cp $(TestScriptDir)/$(TestScriptName) $(SrcDir)/Workspace/$(TestScriptName)
	rm -f $(TestBuildName)
	$(ROJO) build -o $(TestBuildName)
	rm -f $(SrcDir)/Workspace/$(TestScriptName)

clean:
	rm -f $(BuildName)
	rm -f $(TestBuildName)
	rm -f $(SrcDir)/Workspace/$(TestScriptName)


download_deps:
ifeq ($(wildcard $(ROJO)),)
	rm -f -r $(ToolsDir)/rojo.zip

	mkdir $(ToolsDir) || true
	mkdir $(ToolsDir)/$(DETECTED_OS) || true

	curl -4 -L $(Rojo_$(DETECTED_OS)_RELEASE_URL) --output $(ToolsDir)/rojo.zip
	unzip $(ToolsDir)/rojo.zip -d $(ToolsDir)/$(DETECTED_OS)
	mv $(ToolsDir)/$(DETECTED_OS)/rojo.exe $(ROJO)

	rm -f $(ToolsDir)/rojo.zip
endif