dir=${HOME}/Library/Application Support/Steam/steamapps/common/InvisibleInc/InvisibleInc.app/Contents/Resources/mods

all:
	(cd "${HOME}/src/invisible/KWAD builder" &&  bin/osx/builder -i build.lua -o out &&  cp out/gui.kwad ~/src/ui_tweaks)
	zip scripts.zip *.lua
	rm -Rf "$(dir)/workshop-581951281"
	mkdir "$(dir)/workshop-581951281"
	cp gui.kwad scripts.zip modinfo.txt "$(dir)/workshop-581951281/"
	cp gui.kwad scripts.zip modinfo.txt dist
