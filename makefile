
# get the directory where the makefile is. This way we can specify
# paths relative to where the makefile is, even if we are calling
# make from another directory
#
# Note: that last call to abspath() is to remove the ending slash
DIR_MAKEFILE := $(abspath $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
#$(info DIR_MAKEFILE="$(DIR_MAKEFILE)")

# if the user have not provided a value, default to 'release'
CFG ?= release

DIR_SRC := ${DIR_MAKEFILE}/../src
DIR_OUT ?= /tmp/imageviewer/${CFG}
DIR_BIN := ${DIR_OUT}/bin
DIR_OBJ := ${DIR_OUT}/obj
DIR_DEP := ${DIR_OUT}/obj

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
ifeq (${CFG}, debug)
CXX_FLAGS := ${CXX_FLAGS} -g3 -ggdb -D_DEBUG -O0
else ifeq (${CFG}, debug-release)
CXX_FLAGS := ${CXX_FLAGS} -g3 -ggdb -D_DEBUG -O3 -flto -march=native -mtune=native
else
CXX_FLAGS := ${CXX_FLAGS} -O3 -flto -fomit-frame-pointer -DNDEBUG -march=native -mtune=native
endif

CXX_DEP_FLAGS := -MMD 


#SRC_FILES =$(foreach f, $(SRC_FILE_NAMES), $(SRC_DIR)/$f)
SRC_IMAGEVIEWER := \
	../src/imageviewer/main.cpp

OBJ_IMAGEVIEWER := $(patsubst ../src/%.cpp, ${DIR_OBJ}/%.o, ${SRC_IMAGEVIEWER})
DEP_IMAGEVIEWER := $(subst .o,.d, ${OBJ_IMAGEVIEWER})
$(info SRC_IMAGEVIEWER=${SRC_IMAGEVIEWER})
$(info OBJ_IMAGEVIEWER=${OBJ_IMAGEVIEWER})
$(info DEP_IMAGEVIEWER=${DEP_IMAGEVIEWER})


################################################################################
# Recipes
################################################################################

# makes everything
all: imageviewer

# makes the executable
imageviewer: ${OBJ_IMAGEVIEWER}
	${CXX} ${CXX_FLAGS} $^ ${LINK_FLAGS} ${LINK_FLAGS_EXTRA} -o "${DIR_BIN}/imageviewer"

# each object file requires the compilation of its respective source file
${DIR_OBJ}/%.o: ${DIR_SRC}/%.cpp
	${CXX} ${INCLUDE_DIRS} ${CXX_FLAGS} -c $< -o $@ ${CXX_DEP_FLAGS} -MF $(@:.o=.d)	

# deletes all binaries and temporaries
clean:
	-rm -rf "${DIR_OUT}"


################################################################################
# Commands that are always executed
################################################################################

# this will be called when the makefile is parsed. Here we create all required
# dirs. This is much better than creating the dirs inside a makefile rule
# because the command will be called only once




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

-include ${DEP_IMAGEVIEWER}

$(shell mkdir -p ${DIR_BIN})

DIR_OBJ_ALL := $(dir ${OBJ_IMAGEVIEWER})
ifneq (${DIR_OBJ_ALL}, )
$(shell mkdir -p ${DIR_OBJ_ALL})
endif

DIR_DEP_ALL := $(dir ${DEP_IMAGEVIEWER})
ifneq (${DIR_DEP_ALL}, )
$(shell mkdir -p ${DIR_DEP_ALL})
endif

endif
