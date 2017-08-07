#!/usr/bin/env bash
# pass import - Password Store Extension (https://www.passwordstore.org/)
# Copyright (C) 2017 Alexandre PUJOL <alexandre@pujol.io>.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

readonly VERSION="2.0"
readonly LIBDIR="${PASSWORD_STORE_LIBDIR:-/usr/lib/password-store/import}"
readonly PASSWORDS_MANAGERS=("onepassword" "chrome" "dashlane" "enpass" "fpm"
	"gorilla" "kedpm" "keepass" "keepasscsv" "keepassx" "kwallet" "lastpass"
	"passwordexporter" "pwsafe" "revelation" "roboform")

readonly green='\e[0;32m'
readonly Bold='\e[1m'
readonly Bred='\e[1;31m'
readonly Bgreen='\e[1;32m'
readonly reset='\e[0m'
_message() { [ "$QUIET" = 0 ] && echo -e " ${Bold} . ${reset} ${*}" >&2; }
_success() { [ "$QUIET" = 0 ] && echo -e " ${Bgreen}(*)${reset} ${green}${*}${reset}" >&2; }
_error() { echo -e " ${Bred}[x]${reset} ${Bold}Error:${reset} ${*}" >&2; }
_die() { _error "${@}" && exit 1; }

_ensure_dependencies() {
	command -v "python3" &>/dev/null || _die "$PROGRAM $COMMAND requires python3"
	command -v "${LIBDIR}/import.py" &>/dev/null || _die "$PROGRAM $COMMAND requires ${LIBDIR}/import.py"
}

cmd_import_version() {
	cat <<-_EOF
	$PROGRAM $COMMAND $VERSION - A generic importer extension for pass.
	_EOF
}

cmd_import_usage() {
	cmd_import_version
	echo
	cat <<-_EOF
	Usage:
	    $PROGRAM $COMMAND [options] <manager> <file>
	        Import data to a password store.
	        <file> is the path to the file that contains the data to import.
	        <manager> can be: ${PASSWORDS_MANAGERS[@]}

	Options:
	    -q, --quiet    Be quiet
	    -v, --verbose  Be verbose
	    -V, --version  Show version information.
	    -h, --help	   Print this help message and exit.

	More information may be found in the pass-import(1) man page.
	_EOF
}

in_array() {
	local needle=$1; shift
	local item
	for item in "${@}"; do
		[[ "${item}" == "${needle}" ]] && return 0
	done
	return 1
}

cmd_import() {
	local importer_path importer="$1"; shift;
	[[ -z "$importer" ]] && _die "$PROGRAM $COMMAND <importer> [ARG]"

	check_sneaky_paths "$importer"
	if in_array "$importer" "${!IMPORTERS[@]}"; then
		importer_path=$(find "$IMPORTER_DIR/${importer}2pass".* 2> /dev/null)
		[[ -x "$importer_path" ]] || _die "Unable to find $importer_path"
		_ensure_dependencies "$importer"
		"${IMPORTERS[$importer]}" "$importer_path" "$@"
	else
		_die "$importer is not a supported importer"
	fi
}

# Check dependencies are present or bail out
_ensure_dependencies

# Global options
VERBOSE=0
QUIET=0

# Getopt options
small_arg="vhVq"
long_arg="verbose,help,version,quiet"
opts="$($GETOPT -o $small_arg -l $long_arg -n "$PROGRAM $COMMAND" -- "$@")"
err=$?
eval set -- "$opts"
while true; do case $1 in
	-q|--quiet) QUIET=1; VERBOSE=0; shift ;;
	-v|--verbose) VERBOSE=1; shift ;;
	-h|--help) shift; cmd_import_usage; exit 0 ;;
	-V|--version) shift; cmd_import_version; exit 0 ;;
	--) shift; break ;;
esac done

[[ $err -ne 0 ]] && cmd_import_usage && exit 1
cmd_import "$@"
