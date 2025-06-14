# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.22

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/thahn1230/llama.cpp

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/thahn1230/llama.cpp/build_x86

# Include any dependencies generated for this target.
include tools/mtmd/CMakeFiles/mtmd_shared.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include tools/mtmd/CMakeFiles/mtmd_shared.dir/compiler_depend.make

# Include the progress variables for this target.
include tools/mtmd/CMakeFiles/mtmd_shared.dir/progress.make

# Include the compile flags for this target's objects.
include tools/mtmd/CMakeFiles/mtmd_shared.dir/flags.make

# Object files for target mtmd_shared
mtmd_shared_OBJECTS =

# External object files for target mtmd_shared
mtmd_shared_EXTERNAL_OBJECTS = \
"/home/thahn1230/llama.cpp/build_x86/tools/mtmd/CMakeFiles/mtmd.dir/mtmd.cpp.o" \
"/home/thahn1230/llama.cpp/build_x86/tools/mtmd/CMakeFiles/mtmd.dir/mtmd-helper.cpp.o" \
"/home/thahn1230/llama.cpp/build_x86/tools/mtmd/CMakeFiles/mtmd.dir/clip.cpp.o"

bin/libmtmd_shared.so: tools/mtmd/CMakeFiles/mtmd.dir/mtmd.cpp.o
bin/libmtmd_shared.so: tools/mtmd/CMakeFiles/mtmd.dir/mtmd-helper.cpp.o
bin/libmtmd_shared.so: tools/mtmd/CMakeFiles/mtmd.dir/clip.cpp.o
bin/libmtmd_shared.so: tools/mtmd/CMakeFiles/mtmd_shared.dir/build.make
bin/libmtmd_shared.so: bin/libllama.so
bin/libmtmd_shared.so: tools/mtmd/libmtmd_audio.a
bin/libmtmd_shared.so: bin/libggml.so
bin/libmtmd_shared.so: bin/libggml-cpu.so
bin/libmtmd_shared.so: bin/libggml-base.so
bin/libmtmd_shared.so: tools/mtmd/CMakeFiles/mtmd_shared.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/thahn1230/llama.cpp/build_x86/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Linking CXX shared library ../../bin/libmtmd_shared.so"
	cd /home/thahn1230/llama.cpp/build_x86/tools/mtmd && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mtmd_shared.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
tools/mtmd/CMakeFiles/mtmd_shared.dir/build: bin/libmtmd_shared.so
.PHONY : tools/mtmd/CMakeFiles/mtmd_shared.dir/build

tools/mtmd/CMakeFiles/mtmd_shared.dir/clean:
	cd /home/thahn1230/llama.cpp/build_x86/tools/mtmd && $(CMAKE_COMMAND) -P CMakeFiles/mtmd_shared.dir/cmake_clean.cmake
.PHONY : tools/mtmd/CMakeFiles/mtmd_shared.dir/clean

tools/mtmd/CMakeFiles/mtmd_shared.dir/depend:
	cd /home/thahn1230/llama.cpp/build_x86 && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/thahn1230/llama.cpp /home/thahn1230/llama.cpp/tools/mtmd /home/thahn1230/llama.cpp/build_x86 /home/thahn1230/llama.cpp/build_x86/tools/mtmd /home/thahn1230/llama.cpp/build_x86/tools/mtmd/CMakeFiles/mtmd_shared.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : tools/mtmd/CMakeFiles/mtmd_shared.dir/depend

