#!/usr/bin/env bash

declare -r BLACK="$(tput setaf 237)"
declare -r RED="$(tput setaf 1)"
declare -r GREEN="$(tput setaf 2)"
declare -r YELLOW="$(tput setaf 3)"
declare -r MAGENTA="$(tput setaf 4)"
declare -r RESET="$(tput sgr0)"

declare -r PREFIX_ON_RESIZING="[resizing] "
declare -r PREFIX_ON_OPTIMIZATION_STEP_1="[optimization/step #1] "
declare -r PREFIX_ON_OPTIMIZATION_STEP_2="[optimization/step #2] "
declare -r PREFIX_ON_OPTIMIZATION_STEP_3="[optimization/step #3] "
declare -r PREFIX_ON_OPTIMIZATION_WITHOUT_STEPS="[optimization] "
declare -r PREFIX_ON_OPTIMIZATION_TOTAL="[optimization/total] "
declare -r PREFIX_ON_TOTAL="[total] "
declare -r PREFIX_ON_GLOBAL_TOTAL="[global total] "

function extension() {
	declare -r file="$1"

	# check that the file has an extension
	if [[ "$file" != *.* ]]; then
		return
	fi

	declare -r file_in_lowercase="${file,,}"
	declare -r extension_without_period="${file_in_lowercase##*.}"
	echo ".$extension_without_period"
}

function size() {
	declare -r file="$1"

	stat --format=%s "$file"
}

function resolution() {
	declare -r file="$1"

	identify -format "%wx%h" "$file"
}

function ansi() {
	declare -r code="$1"
	declare -r text="$2"

	echo -n "$code$text$RESET"
}

function log() {
	declare -r level="$1"

	shift # a shift for the first parameter
	declare -r message="$*"

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

function log_size_change() {
	declare -r prefix="$1"
	declare -r -i original_size="$2"
	declare -r -i current_size="$3"

	declare suffix_with_saved_size=""
	if [[ $original_size != 0 ]]; then
		declare -r current_size_in_percent="$(
			bc <<< "scale = 6; $current_size / $original_size * 100")"
		declare -r saved_size="$(
			bc <<< "100 - $current_size_in_percent")"
		declare -r formatted_saved_size="$(
			LC_NUMERIC=en_US.UTF-8 printf "%.2f%%" "$saved_size")"

		suffix_with_saved_size="(saved $(ansi "$MAGENTA" "$formatted_saved_size"))"
	fi

	log INFO "${prefix}the file size has changed" \
		"from $(ansi "$MAGENTA" $original_size) B" \
		"to $(ansi "$MAGENTA" $current_size) B" \
		"$suffix_with_saved_size"
}

declare -r script_name="$(basename "$0")"
# it's necessary to separate the declaration and definition of the variable
# so that the `declare` command doesn't hide an exit code of the defining expression
declare options
options="$(
	getopt \
		--name "$script_name" \
		--options "vhn:rw:" \
		--longoptions "version,help,name:,recursive,width:,no-process,no-resize,no-optimize" \
		-- "$@"
)"
if [[ $? != 0 ]]; then
	log ERROR "incorrect option"
	exit 1
fi

declare name_pattern="(?i)\.(png|jpe?g)"
declare recursive=FALSE
declare -i maximal_width=640
declare process=TRUE
declare resize=TRUE
declare optimize=TRUE
eval set -- "$options"
while [[ "$1" != "--" ]]; do
	case "$1" in
		"-v" | "--version")
			echo "Image Preparer, v1.3.0"
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
				"(uses Perl-compatible regular expressions (PCREs);" \
				'default: "(?i)\.(png|jpe?g)");'
			echo "  -r, --recursive             - recursive search of images;"
			echo "  -w WIDTH, --width WIDTH     - a maximum width of images" \
				"(default: 640);"
			echo "  --no-process                - don't process images," \
				"only search for them and check their size;"
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
		"--no-process")
			process=FALSE
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

set -o errtrace
trap 'log WARNING "unable to process the $(ansi "$YELLOW" "$image") image"' ERR

declare -a search_depth=()
if [[ $recursive != TRUE ]]; then
	search_depth=("-maxdepth" "1")
fi

find "$base_path" "${search_depth[@]}" -type f \
| grep --perl-regexp "$name_pattern" \
| {
	declare -i image_count=0
	declare -i initial_total_size=0
	declare -i final_total_size=0
	while read -r; do
		declare image="$REPLY"

		(( image_count++ )) || true # ignore an error since a zero value counts as an error
		log INFO "[image $(ansi "$MAGENTA" \#$image_count)] process" \
			"the $(ansi "$YELLOW" "$image") image"

		declare -i initial_size=$(size "$image")
		(( initial_total_size += initial_size ))

		declare -i current_size=$initial_size
		declare was_resized=FALSE
		if [[ $resize == TRUE ]]; then
			declare initial_resolution="$(resolution "$image")"
			declare -i initial_width="${initial_resolution%x*}"
			if (( initial_width > maximal_width )); then
				if [[ $process == TRUE ]]; then
					log INFO "${PREFIX_ON_RESIZING}resize" \
						"the $(ansi "$YELLOW" "$image") image"
					convert "$image" -filter Lanczos -resize $maximal_width\> "$image"

					declare resolution_after_resizing="$(resolution "$image")"
					log INFO "${PREFIX_ON_RESIZING}the image resolution has changed" \
						"from $(ansi "$MAGENTA" "$initial_resolution")" \
						"to $(ansi "$MAGENTA" "$resolution_after_resizing")"

					declare -i size_after_resizing=$(size "$image")
					log_size_change "$PREFIX_ON_RESIZING" $current_size $size_after_resizing
					current_size=$size_after_resizing

					was_resized=TRUE
				else
					log WARNING "${PREFIX_ON_RESIZING}the $(ansi "$YELLOW" "$image") image" \
						"has a not allowed resolution $(ansi "$MAGENTA" "$initial_resolution")"
				fi
			else
				log INFO "${PREFIX_ON_RESIZING}the $(ansi "$YELLOW" "$image") image" \
					"has an allowed resolution $(ansi "$MAGENTA" "$initial_resolution")"
			fi
		fi

		if [[ $optimize == TRUE && $process == TRUE ]]; then
			case "$(extension "$image")" in
				".png")
					declare -i size_before_optimization=$current_size

					log INFO "${PREFIX_ON_OPTIMIZATION_STEP_1}optimize" \
						"the $(ansi "$YELLOW" "$image") image"
					pngquant --ext=.png --force --skip-if-larger --strip --speed=1 "$image"

					declare -i size_after_optimization_step_1=$(size "$image")
					log_size_change \
						"$PREFIX_ON_OPTIMIZATION_STEP_1" \
						$current_size \
						$size_after_optimization_step_1
					current_size=$size_after_optimization_step_1

					log INFO "${PREFIX_ON_OPTIMIZATION_STEP_2}optimize" \
						"the $(ansi "$YELLOW" "$image") image"
					optipng -quiet -strip=all -i0 -o1 "$image"

					declare -i size_after_optimization_step_2=$(size "$image")
					log_size_change \
						"$PREFIX_ON_OPTIMIZATION_STEP_2" \
						$current_size \
						$size_after_optimization_step_2
					current_size=$size_after_optimization_step_2

					log INFO "${PREFIX_ON_OPTIMIZATION_STEP_3}optimize" \
						"the $(ansi "$YELLOW" "$image") image"
					advpng --recompress --quiet --shrink-extra "$image"

					declare -i size_after_optimization_step_3=$(size "$image")
					log_size_change \
						"$PREFIX_ON_OPTIMIZATION_STEP_3" \
						$current_size \
						$size_after_optimization_step_3
					current_size=$size_after_optimization_step_3

					log_size_change \
						"$PREFIX_ON_OPTIMIZATION_TOTAL" \
						$size_before_optimization \
						$current_size

					;;

				".jpg" | ".jpeg")
					log INFO "${PREFIX_ON_OPTIMIZATION_WITHOUT_STEPS}optimize" \
						"the $(ansi "$YELLOW" "$image") image"
					# the maximum quality factor is based on the following article:
					# https://sirv.com/help/articles/jpeg-quality-comparison/
					jpegoptim --quiet --strip-all --all-normal --max=80 "$image"

					declare -i size_after_optimization=$(size "$image")
					log_size_change \
						"$PREFIX_ON_OPTIMIZATION_WITHOUT_STEPS" \
						$current_size \
						$size_after_optimization
					current_size=$size_after_optimization

					;;

			esac
		fi

		(( final_total_size += current_size ))
		if [[ $was_resized == TRUE && $optimize == TRUE ]]; then
			log_size_change "$PREFIX_ON_TOTAL" $initial_size $current_size
		fi
	done

	if [[ $image_count != 0 && $process == TRUE ]]; then
		log_size_change "$PREFIX_ON_GLOBAL_TOTAL" $initial_total_size $final_total_size
	fi
}
