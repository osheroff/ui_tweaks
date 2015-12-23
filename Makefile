dir=${HOME}/Library/Application Support/Steam/steamapps/common/InvisibleInc/InvisibleInc.app/Contents/Resources/mods

all:
	zip scripts.zip *.lua
	rm -Rf "$(dir)/ui_tweaks"
	mkdir "$(dir)/ui_tweaks"
	cp -a * "$(dir)/ui_tweaks"
