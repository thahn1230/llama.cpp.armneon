file(REMOVE_RECURSE
  "../../bin/libmtmd_shared.pdb"
  "../../bin/libmtmd_shared.so"
)

# Per-language clean rules from dependency scanning.
foreach(lang CXX)
  include(CMakeFiles/mtmd_shared.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
