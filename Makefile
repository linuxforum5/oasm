SRC=src
WBIN=win32
BIN=bin
INSTALL_DIR=~/.local/bin
CC=gdc
WCC=i686-w64-mingw32-gcc
BASENAME=oasm
D_FILES=$(shell find ./$(SRC)/classes -type f -name '*.d')

all: main

main: $(SRC)/$(BASENAME).d $(D_FILES)
	$(CC)  $(D_FILES) $(SRC)/$(BASENAME).d -g -o $(BIN)/$(BASENAME)
	# $(WCC) $(D_FILES) $(SRC)/$(BASENAME).d -g -o $(WBIN)/$(BASENAME)

clean:
	rm -f $(WBIN)/* $(BIN)/* *~ $(SRC)/*~.

install:
	cp $(BIN)/* $(INSTALL_DIR)/
