#! /usr/bin/env sh


LOG_SRC=1

#---------#
# Imports #
#---------#

currentDir="$( cd "$( dirname "${0}" )" && pwd )"
import config-utils


#------#
# Init #
#------#

__log_debug_enabled=0
__log_debug_print () {
  local msg="${1}"
  if [ "${__log_debug_enabled}" = 1 ]; then
    printf "debug: %b\n" "${msg}" >&1
  fi
}
__log_debug_print "entering log"


#-----#
# API #
#-----#

#-------------------------------
#
# Function: log <level> <message>
#
# Arguments:
#   <level> - The level which the message will be logged as.
#   <message> - The message to be logged.
#
# Description: Logs a message to stdout if:
#                1) <level> is greather than or equal to the configurable 'stdout_level', and
#                2) <level> is less than or equal to 'error'
#                If <level> is equal to 'error', then this method logs to stderr.
#                If <level> is less than 1 or greather than 5, an error is logged stating such,
#                  then <level> is set to 5.
#                Please note this function does _not_ support level 6 'fatal'.  Please use 'log_fatal'
#                  for that.  Currently there only exists logging to stdout and stderr, but this
#                  library could be written to support other types (file, database, etc).
#
#-------------------------------
#
# Function: log_fatal <message> [errno]
#
# Arguments:
#   <message> - The message to be logged.
#   [errno ^1] - The caller can optionally pass an error number for which the program exits with.
#                  [errno] must be between 1 and 255.
#
# Description: Logs the <message> and generated callstack to stderr then exits the script with [errno].
#
#-------------------------------
#
# Function: log_print_stdout_level
#
# Description: Prints the 'stdout_level' stored in the file '.log.config'.  If .log.config doesn't
#                exist then it is created.  If it doesn't contain the configured 'stdout_level', then
#                that namve/value pair is written to the file and defaulted to 5.
#
#-------------------------------
#
# Function log_set_stdout_level <level>
#
# Arguments:
#   <level> - The level which 'stdout_level' is set to.  Must be between 1 and 5.
#
# Description: Sets the 'stdout_level' located in the file '__log_conf'.  This value is what 'log' uses
#                to determine whether the message is printed to stdout.  Level 5 implies no logs will
#                be created under stdout, because all errors will be written to stderr.
#
#-------------------------------


#---------------------#
# Misc. Documentation #
#---------------------#

#-------------------------------
#
# Log levels
# 1 - trace
# 2 - debug
# 3 - info
# 4 - warning
# 5 - error
# 6 - fatal
#
#-------------------------------


#------------------#
# Script Variables #
#------------------#

__log_trace="trace"
__log_debug="debug"
__log_info="info"
__log_warning="warning"
__log_error="error"
__log_fatal="fatal"
__log_dbg_enabled=1
__log_res=
__log_conf="${currentDir}/.log.conf"
__log_stdout_name="stdout_level"


#-----------#
# Functions #
#-----------#

log () {
  __log_validate_message_level "${1}"
  local lvl="${__log_res}"
  
  __log_get_label "${lvl}"
  local label="${__log_res}"
  
  __log_validate_message "log" "${2}"
  local msg="${__log_res}"
  
  msg="${label}: ${msg}\n"
  __log_get_stdout_level
  local stdout_level="${__log_res}"
  
  if [ "${lvl}" = 5 ]; then
    printf "%b" "${msg}" >&2
    elif [ "${lvl}" -ge "${stdout_level}" ]; then
    printf "%b" "${msg}" >&1
  fi
}

log_fatal () {
  __log_validate_message "log_fatal" "${1}"
  local msg="${__log_fatal}: ${__log_res}"
  
  __log_validate_errno "${2}"
  local errno="${__log_res}"
  
  printf "%b" "${result}" >&2
  exit "${errno}"
}

log_print_stdout_level () {
  __log_get_stdout_level
  printf "Current stdout log level: %b\n" "${__log_res}" >&1
}

log_set_stdout_level () {
  __log_validate_stdout_level "${1}"
  local level="${__log_res}"
  
  touch "${__log_conf}"
  cu_set_name_value "${__log_stdout_name}" "${level}" "${__log_conf}"
  
  if [ "${debug_enabled}" = 1 ]; then
    printf "stdout_level=%b\n" "${level}" >&1
  fi
}


#------------------#
# Helper Functions #
#------------------#

__log_validate_stdout_level () {
  local level="${1}"
  
  if [ "${level}" = "" ]; then
    printf "stdout level wasn't provided\n" >&2
    exit 1
    elif [ ! "${level}" -eq "${level}" ]; then
    printf "%b: level must be an integer between 1 and 5\n" "${__log_fatal}" >&2
    exit 1
    elif [ "${level}" -lt 1 ] || [ "${level}" -gt 5 ]; then
    printf "%b: message level cannot be less than 1 nor greater than 5 - defaulting to 5\n" "${__log_error}" >&2
    level=5
  fi
  
  __log_res="${level}"
}

__log_validate_message_level () {
  local level="${1}"
  
  if [ "${level}" -lt 1 ] || [ "${level}" -gt 5 ]; then
    printf "%b: message level cannot be less than 1 nor greater than 5 - defaulting to 5\n" "${__log_error}" >&2
    level=5
  fi
  
  __log_res="${level}"
}

__log_validate_message () {
  local fnName="${1}"
  if [ -z "${2+x}" ] || [ "${2}" = "" ]; then
    printf "%b: '${fnName}' was called without a message argument.\n" "${__log_fatal}" >&2
    exit 1
  fi
  
  __log_res="${2}"
}

__log_validate_errno () {
  local errno=1
  if [ "${1}" -eq "${1}" ] 2>/dev/null && [ ! "${1}" = "0" ] ; then
    errno="${1}"
    if [ "${1}" -gt 255 ] || [ "${1}" -lt 1 ]; then
      printf "%b: 'log_fatal' was called with an errno" "${__log_warning}" >&1
      printf " greater than 255 or less than 1.  This may invoke an unexpected exit code.\n" >&1
    fi
    elif [ ! "${1}" = "" ]; then
    printf "%b: 'log_fatal' was called with an invalid errno: '%b'.\n" "${__log_fatal}" "${1}" >&2
    exit 1
  fi
  
  __log_res="${errno}"
}

__log_get_label () {
  local label=
  case "${1}" in
    1) label="${__log_trace}" ;;
    2) label="${__log_debug}" ;;
    3) label="${__log_info}" ;;
    4) label="${__log_warning}" ;;
    5) label="${__log_error}" ;;
    6) label="${__log_fatal}" ;;
    *)
      printf "%b: 'log' was called with an invalid level: '${1}'.\n" "${__log_fatal}" >&2
    ;;
  esac
  
  __log_res="${label}"
}

__log_get_stdout_level () {
  local level=
  if [ ! -f "${__log_conf}" ]; then
    touch "${__log_conf}"
    cu_set_name_value "${__log_stdout_name}" 5 "${__log_conf}"
    level=5
  else
    cu_get_value "${__log_stdout_name}" "file=${__log_conf}"
    if [ "${config_utils_result}" = "" ]; then
      cu_set_name_value "${__log_stdout_name}" 5 "${__log_conf}"
      level=5
    else
      level="${config_utils_result}"
    fi
  fi
  
  __log_res="${level}"
}


__log_debug_print "exiting log"
