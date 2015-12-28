#! /bin/bash

#---------------------------#
# Test file for file_exists #
#---------------------------#

if [ -z "${IMPORT_SRC+x}" ]; then
  source "${LIBRARY_FXNS}/import"
fi
import "file_exists"
import "test_utils"

tu_init

tu_assert_success "file_exists ./.file_exists.test" "file_exists" "file does exist"
tu_assert_errno "file_exists ./.file_exists.nothere" \
"2" \
"file_exists" \
"file does not exist"

tu_assert_errno "file_exists" \
"3" \
"file_exists" \
"no arguments"

tu_finalize