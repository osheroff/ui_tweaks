dir=${HOME}/Library/Application Support/Steam/steamapps/common/InvisibleInc/InvisibleInc.app/Contents/Resources/mods

all:
	zip scripts.zip *.lua socket.so
	rm -Rf "$(dir)/workshop-581951281"
	mkdir "$(dir)/workshop-581951281"
	cp scripts.zip modinfo.txt "$(dir)/workshop-581951281/"
	cp scripts.zip modinfo.txt dist
