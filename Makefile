ToolsDir = ./Tools

ROJO_RELEASE_URL = https://github.com/rojo-rbx/rojo/releases/download/v0.5.4/rojo-0.5.4-win64.zip
ROJO = $(ToolsDir)/rojo.exe

BuildName = build.rbxlx

.PHONY: download_deps force_download_deps build

build: clean download_deps
	$(ROJO) build -o $(BuildName)

clean:
	rm $(BuildName)

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