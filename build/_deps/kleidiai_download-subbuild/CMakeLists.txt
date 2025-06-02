# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.22.1)

# We name the project and the target for the ExternalProject_Add() call
# to something that will highlight to the user what we are working on if
# something goes wrong and an error message is produced.

project(kleidiai_download-populate NONE)



include(ExternalProject)
ExternalProject_Add(kleidiai_download-populate
                     "UPDATE_DISCONNECTED" "False" "URL" "https://github.com/ARM-software/kleidiai/archive/refs/tags/v1.6.0.tar.gz" "DOWNLOAD_EXTRACT_TIMESTAMP" "NEW" "URL_HASH" "MD5=75b4ad68f25ab673dcc01065e5a0b05f"
                    SOURCE_DIR          "/home/thahn1230/llama.cpp/build/_deps/kleidiai_download-src"
                    BINARY_DIR          "/home/thahn1230/llama.cpp/build/_deps/kleidiai_download-build"
                    CONFIGURE_COMMAND   ""
                    BUILD_COMMAND       ""
                    INSTALL_COMMAND     ""
                    TEST_COMMAND        ""
                    USES_TERMINAL_DOWNLOAD  YES
                    USES_TERMINAL_UPDATE    YES
)


