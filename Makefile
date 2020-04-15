ROJO_RELEASE_URL = https://github.com/rojo-rbx/rojo/releases/download/v0.5.4/rojo-0.5.4-win64.zip
ROJO = $(ToolsDir)/rojo.exe

TestScriptName = test.server.lua
TestScriptDir = ./TestPlaceScript
ToolsDir = ./Tools
SrcDir = ./src

BuildName = build.rbxlx
TestBuildName = test.rbxlx

.PHONY: download_deps force_download_deps build clean test

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
	rm -f -r $(ToolsDir)
	mkdir $(ToolsDir) || true
	curl -4 -L $(ROJO_RELEASE_URL) --output $(ToolsDir)/rojo.zip
	unzip $(ToolsDir)/rojo.zip -d $(ToolsDir)
	rm -f $(ToolsDir)/rojo.zip
endif

force_download_deps:
	rm -f -r $(ToolsDir)
	mkdir $(ToolsDir) || true
	curl -4 -L $(ROJO_RELEASE_URL) --output $(ToolsDir)/rojo.zip
	unzip $(ToolsDir)/rojo.zip -d $(ToolsDir)
	rm -f $(ToolsDir)/rojo.zip