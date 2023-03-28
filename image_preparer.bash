#!/usr/bin/env bash

declare -r BLACK="$(tput setaf 237)"
declare -r RED="$(tput setaf 1)"
declare -r GREEN="$(tput setaf 2)"
declare -r YELLOW="$(tput setaf 3)"
declare -r RESET="$(tput sgr0)"

function ansi() {
	declare -r code="$1"
	declare -r text="$2"

	echo -n "$code$text$RESET"
}

function log() {
	declare -r level="$1"
	declare -r message="$2"

	declare level_color=""
	if [[ $level == INFO ]]; then
		level_color="$GREEN"
	elif [[ $level == WARNING ]]; then
		level_color="$YELLOW"
	elif [[ $level == ERROR ]]; then
		level_color="$RED"
	fi

	echo "$(ansi "$BLACK" "$(date --rfc-3339=ns)")" \
		"$(ansi "$level_color" "[$level]")" \
		"$message" \
		1>&2
}

declare -r script_name="$(basename "$0")"
# it's necessary to separate the declaration and definition of the variable
# so that the `declare` command doesn't hide an exit code
# of the defining expression
declare options
options="$(
	getopt \
		--name "$script_name" \
		--options "vhn:rw:" \
		--longoptions "version,help,name:,recursive,width:,no-resize,no-optimize" \
		-- "$@"
)"
if [[ $? != 0 ]]; then
	log ERROR "incorrect option"
	exit 1
fi

declare name_pattern="*.png"
declare recursive=FALSE
declare -i maximal_width=640
declare resize=TRUE
declare optimize=TRUE
eval set -- "$options"
while [[ "$1" != "--" ]]; do
	case "$1" in
		"-v" | "--version")
			echo "Image Preparer, v1.0.0"
			echo "Copyright (C) 2018, 2023 thewizardplusplus"

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
			echo "  -n PATTERN, --name PATTERN  - a pattern of image filenames" \
				'(uses a name pattern of the `find` tool; default: "*.png");'
			echo "  -r, --recursive             - recursive search of images;"
			echo "  -w WIDTH, --width WIDTH     - a maximum width of images" \
				'(default: 640);'
			echo "  --no-resize                 - don't resize images;"
			echo "  --no-optimize               - don't optimize images."
			echo
			echo "Arguments:"
			echo "  <path>                      - base path to images" \
				'(default: ".").'

			exit 0
			;;
		"-n" | "--name")
			name_pattern="$2"

			shift # an additional shift for the option parameter
			;;
		"-r" | "--recursive")
			recursive=TRUE
			;;
		"-w" | "--width")
			maximal_width="$2"

			shift # an additional shift for the option parameter
			;;
		"--no-resize")
			resize=FALSE
			;;
		"--no-optimize")
			optimize=FALSE
			;;
	esac

	shift
done
if [[ $resize == FALSE && $optimize == FALSE ]]; then
	log ERROR "both resizing and optimization are forbidden: nothing to do"
	exit 1
fi

declare base_path="."
shift # an additional shift for the "--" option
if [[ $# == 1 ]]; then
	base_path="$1"
elif [[ $# > 1 ]]; then
	log ERROR "too many positional arguments"
	exit 1
fi

declare -a search_depth=()
if [[ $recursive != TRUE ]]; then
	search_depth=("-maxdepth" "1")
fi

declare image=""
set -o errtrace
trap 'log WARNING "unable to process the $(ansi "$YELLOW" "$image") image"' ERR

find "$base_path" \
	"${search_depth[@]}" \
	-type f \
	-name "$name_pattern" \
| while read -r; do
	image="$REPLY"

	if [[ $resize == TRUE ]]; then
		log INFO "resize the $(ansi "$YELLOW" "$image") image"
		convert "$image" -filter lanczos -resize $maximal_width\> "$image"
	fi

	if [[ $optimize == TRUE && "${image: -4}" == ".png" ]]; then
		log INFO "optimize the $(ansi "$YELLOW" "$image") image (step 1)"
		pngquant --ext=.png --force --skip-if-larger --speed=1 --strip "$image"

		log INFO "optimize the $(ansi "$YELLOW" "$image") image (step 2)"
		optipng -quiet -strip=all -i0 -o1 "$image"
	fi
done
