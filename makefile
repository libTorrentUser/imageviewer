
# get the directory where the makefile is. This way we can specify
# paths relative to where the makefile is, even if we are calling
# make from another directory
#
# Note: that last call to abspath() is to remove the ending slash
MAKEFILE_DIR := $(abspath $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
#$(info MAKEFILE_DIR="$(MAKEFILE_DIR)")

# if the user have not provided a value, default to 'release'
CFG ?= release

DIR_SRC := $(MAKEFILE_DIR)/../src
DIR_OUT ?= /tmp/imageviewer/${CFG}
DIR_BIN := $(OUT)/bin
DIR_OBJ := $(OUT)/obj
DIR_DEP := $(OUT)/obj

# number of processors (or 1, if nproc is not available)
#PROCESSORCOUNT := $(shell nproc || printf 1)

# tell make to run jobs in parallel, one for each processor
#MAKEFLAGS += -j$(PROCESSORCOUNT)
# let the user define -j. It works though...

# the compiler
CXX := g++

# if make is called with CFG=debug,
# we will add debug options to the compiler flags
#
# if make is called with CFG=debug-release,
# we will add debug flags to the compiler flags but will also add the flags we
# use dugin a release build, except we won't define NDEBUG 
#
# otherwise we assume it is a release build
# we will set no debug information and add optimization flags
CXX_FLAGS := -Wall -Wextra -Werror -Wfatal-errors -std=c++23 -Wno-unused-function -Wno-unused-but-set-variable
ifeq ($(CFG), debug)
CXX_FLAGS := $(CXX_FLAGS) -g3 -ggdb -D_DEBUG -O0
else ifeq ($(CFG), debug-release)
CXX_FLAGS := $(CXX_FLAGS) -g3 -ggdb -D_DEBUG -O3 -flto -march=native -mtune=native
else
CXX_FLAGS := $(CXX_FLAGS) -O3 -flto -fomit-frame-pointer -DNDEBUG -march=native -mtune=native
endif

CXX_DEP_FLAGS := -MMD 


#SRC_FILES =$(foreach f, $(SRC_FILE_NAMES), $(SRC_DIR)/$f)
SRC_IMAGEVIEWER := \
	../src/imageviewer/main.cpp

OBJ_IMAGEVIEWER := $(patsubst ../src/%.cpp, $(OBJ_DIR)/%.o, $(SRC_IMAGEVIEWER))
$(info OBJ_IMAGEVIEWER=$(OBJ_IMAGEVIEWER))

DEP_FILES := $(subst .o,.d, $(OBJ_FILES))
#$(info OBJ_FILES=$(OBJ_FILES))
#$(info DEP_FILES=$(DEP_FILES))


################################################################################
# Recipes
################################################################################

# makes everything
all: $(EXE)

# makes the executable
$(EXE): $(EXE_PATH)

# the executable requires all object files
$(EXE_PATH): $(OBJ_FILES)
	$(CXX) $(CXX_FLAGS) $^ $(LINK_FLAGS_EXTRA) $(LINK_FLAGS) -o "$(BIN)/$(EXE)"

# each object file requires the compilation of its respective source file
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CXX) $(INCLUDE_DIRS) $(CXX_FLAGS) -c $< -o $@ $(CXX_DEP_FLAGS) -MF $(@:.o=.d)	

# deletes all binaries and temporaries
clean:
	-rm -f "$(EXE_PATH)"
	-rm -rf "$(OBJ_DIR)/"*
	-rm -rf "$(DEP_DIR)/"*


################################################################################
# Commands that are always executed
################################################################################

# this will be called when the makefile is parsed. Here we create all required
# dirs. This is much better than creating the dirs inside a makefile rule
# because the command will be called only once
$(shell mkdir -p $(BIN))

OBJ_DIR_ALL := $(dir $(OBJ_FILES))
ifneq ($(OBJ_DIR_ALL), )
$(shell mkdir -p $(OBJ_DIR_ALL))
endif

DEP_DIR_ALL := $(dir $(DEP_FILES))
ifneq ($(DEP_DIR_ALL), )
$(shell mkdir -p $(DEP_DIR_ALL))
endif

# by instructing make to read an external makefile with "include" it will 
# search for the dependency files. It will see they do not exist but will also
# realize that we have told it how to create them with 
#
# $(DEP_DIR)/%.d: $(SRC)/%.cpp)
#
# So make will generate the dependency files and will learn of all source 
# files dependencies, so every you modify one source file it will know which
# object files it has to rebuild.
#
# www.thanassis.space/makefile.html
# make.mad-scientist.net/papers/advanced-auto-dependency-generation/
ifneq ($(MAKECMDGOALS), clean)
-include $(DEP_FILES)
endif
