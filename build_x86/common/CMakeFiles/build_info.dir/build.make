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
include common/CMakeFiles/build_info.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include common/CMakeFiles/build_info.dir/compiler_depend.make

# Include the progress variables for this target.
include common/CMakeFiles/build_info.dir/progress.make

# Include the compile flags for this target's objects.
include common/CMakeFiles/build_info.dir/flags.make

../common/build-info.cpp: ../common/build-info.cpp.in
../common/build-info.cpp: ../.git/index
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/thahn1230/llama.cpp/build_x86/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating build details from Git"
	cd /home/thahn1230/llama.cpp && /usr/bin/cmake -DMSVC= -DCMAKE_C_COMPILER_VERSION=11.2.0 -DCMAKE_C_COMPILER_ID=GNU -DCMAKE_VS_PLATFORM_NAME= -DCMAKE_C_COMPILER=/usr/bin/cc -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=x86_64 -P /home/thahn1230/llama.cpp/common/cmake/build-info-gen-cpp.cmake

common/CMakeFiles/build_info.dir/build-info.cpp.o: common/CMakeFiles/build_info.dir/flags.make
common/CMakeFiles/build_info.dir/build-info.cpp.o: ../common/build-info.cpp
common/CMakeFiles/build_info.dir/build-info.cpp.o: common/CMakeFiles/build_info.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/thahn1230/llama.cpp/build_x86/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object common/CMakeFiles/build_info.dir/build-info.cpp.o"
	cd /home/thahn1230/llama.cpp/build_x86/common && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT common/CMakeFiles/build_info.dir/build-info.cpp.o -MF CMakeFiles/build_info.dir/build-info.cpp.o.d -o CMakeFiles/build_info.dir/build-info.cpp.o -c /home/thahn1230/llama.cpp/common/build-info.cpp

common/CMakeFiles/build_info.dir/build-info.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/build_info.dir/build-info.cpp.i"
	cd /home/thahn1230/llama.cpp/build_x86/common && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/thahn1230/llama.cpp/common/build-info.cpp > CMakeFiles/build_info.dir/build-info.cpp.i

common/CMakeFiles/build_info.dir/build-info.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/build_info.dir/build-info.cpp.s"
	cd /home/thahn1230/llama.cpp/build_x86/common && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/thahn1230/llama.cpp/common/build-info.cpp -o CMakeFiles/build_info.dir/build-info.cpp.s

build_info: common/CMakeFiles/build_info.dir/build-info.cpp.o
build_info: common/CMakeFiles/build_info.dir/build.make
.PHONY : build_info

# Rule to build all files generated by this target.
common/CMakeFiles/build_info.dir/build: build_info
.PHONY : common/CMakeFiles/build_info.dir/build

common/CMakeFiles/build_info.dir/clean:
	cd /home/thahn1230/llama.cpp/build_x86/common && $(CMAKE_COMMAND) -P CMakeFiles/build_info.dir/cmake_clean.cmake
.PHONY : common/CMakeFiles/build_info.dir/clean

common/CMakeFiles/build_info.dir/depend: ../common/build-info.cpp
	cd /home/thahn1230/llama.cpp/build_x86 && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/thahn1230/llama.cpp /home/thahn1230/llama.cpp/common /home/thahn1230/llama.cpp/build_x86 /home/thahn1230/llama.cpp/build_x86/common /home/thahn1230/llama.cpp/build_x86/common/CMakeFiles/build_info.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : common/CMakeFiles/build_info.dir/depend

