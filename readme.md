simple chooser akin to choose-gui or dmenu written in swift

### installation
This is just a temporary repo for my own use.  Eventually I hope to get this merged upstream.  
To use this forked version, first, clone this branch from the repo:
```bash
git clone  -single-branch --branch fzy-v1 https://github.com/qiUip/dmenu-swift.git
```
Then, you can then `cd` to the directory and use `make`: 
```
cd dmenu
make
```
This will automatically pull [`fzy`](https://github.com/jhawthorn/fzy) in a submodule, build it as a light minimal library, and continue to build `dmenu`

### usage:
```bash
ls | ./dmenu -p "Select a file" -i -l
```

### arguments(all optional):
```bash
-a # enables auto-selecting the last item
-c # enables consecutive matching
-p "" # prompt in search box(default is "Search")
-i # enables search icon
-xs # extra small window
-s # small window
-m # medium window(default)
-l # large window
-w NUM # manually sets window width in pixels (default set by window size)
-r NUM # manually sets maximum number of rows (default set by window size)
--lock # doesn't allow selections, essentially acts as a display menu
--font "" # set the font name (default is system font)
--bg-color HEX # set the background tint ('#RRGGBBAA' or '#RRGGBB')
--text-color HEX # sets item text color
--highlight-color HEX # sets item highlight color
```

### how fuzzy matching works
Matching uses fuzzy searching with [`fzy`](https://github.com/jhawthorn/fzy).  
There are two modes for matching, `gaps`, which allows gaps between characters for looser matching, and `consecutive` which only matches consecutive characters with no gaps.
