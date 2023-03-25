#!/usr/bin/env bash

declare -r BLACK="$(tput setaf 0)"
declare -r RED="$(tput setaf 1)"
declare -r GREEN="$(tput setaf 2)"
declare -r YELLOW="$(tput setaf 3)"
declare -r RESET="$(tput sgr0)"

declare base_path="."
declare name_pattern="*.png"
declare recursive=FALSE
declare -i maximal_width=640
declare optimize=TRUE

function ansi() {
	declare -r code="$1"
	declare -r text="$2"

	echo -n "$code$text$RESET"
}

function log() {
	declare -r level="$1"
	declare -r message="$2"

	declare level_color=""
	if [[ $level == INFO ]]
	then
		level_color="$GREEN"
	elif [[ $level == WARNING ]]
	then
		level_color="$YELLOW"
	elif [[ $level == ERROR ]]
	then
		level_color="$RED"
	fi

	echo "$(ansi "$BLACK" "$(date --rfc-3339=ns)")" \
		"$(ansi "$level_color" [$level])" \
		"$message" \
		1>&2
}

declare -r script_name="$(basename "$0")"
# it's necessary to separate the variable declaration and its definition so that
# the declare command doesn't hide an exit code of the defining expression
declare options
options="$(
	getopt \
		--name "$script_name" \
		--options "vhn:rw:" \
		--longoptions "version,help,name:,recursive,width:,no-optimize" \
		-- "$@"
)"
if [[ $? != 0 ]]
then
	log ERROR "incorrect option"
	exit 1
fi

eval set -- "$options"
while [[ "$1" != "--" ]]
do
	case "$1" in
		"-v" | "--version")
			echo "Image Preparer, v1.0"
			echo "Copyright (C) 2017 thewizardplusplus"

			exit 0
			;;
		"-h" | "--help")
			echo "Usage:"
			echo "  $script_name -v | --version"
			echo "  $script_name -h | --help"
			echo "  $script_name [options] [<path>]"
			echo
			echo "Options:"
			echo "  -v, --version               - show the version;"
			echo "  -h, --help                  - show the help;"
			echo "  -n PATTERN, --name PATTERN  - pattern of images filenames" \
				'(uses a name pattern of the find tool; default: "*.png");'
			echo "  -r, --recursive             - recursive search of images;"
			echo "  -w WIDTH, --width WIDTH     - maximal width of images" \
				'(default: 640);'
			echo "  --no-optimize               - not to optimize images."
			echo
			echo "Arguments:"
			echo "  <path>                      - base path of images" \
				'(default: ".").'

			exit 0
			;;
		"-n" | "--name")
			name_pattern="$2"

			# additional shift for the option parameter
			shift
			;;
		"-r" | "--recursive")
			recursive=TRUE
			;;
		"-w" | "--width")
			maximal_width="$2"

			# additional shift for the option parameter
			shift
			;;
		"--no-optimize")
			optimize=FALSE
			;;
	esac

	shift
done

# additional shift for the "--" option
shift
if [[ $# == 1 ]]
then
	base_path="$1"
elif [[ $# > 1 ]]
then
	log ERROR "too many positional arguments"
	exit 1
fi

declare -a search_depth=()
if [[ $recursive != TRUE ]]
then
	search_depth=("-maxdepth" "1")
fi

declare image=""
set -o errtrace
trap 'log WARNING "unable to process the $(ansi "$YELLOW" "$image") image"' ERR

find "$base_path" \
	"${search_depth[@]}" \
	-type f \
	-name "$name_pattern" \
| while read -r
do
	image="$REPLY"

	log INFO "resize the $(ansi "$YELLOW" "$image") image"
	convert "$image" -filter lanczos -resize $maximal_width\> "$image"

	if [[ $optimize == TRUE && "${image: -4}" == ".png" ]]
	then
		log INFO "optimize the $(ansi "$YELLOW" "$image") image (step 1)"
		pngquant --ext=.png --force --skip-if-larger --speed=1 --strip "$image"

		log INFO "optimize the $(ansi "$YELLOW" "$image") image (step 2)"
		optipng -quiet -strip=all -i0 -o1 "$image"
	fi
done
