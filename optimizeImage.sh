#!/bin/bash -i

####################################################
## Varriables

E_RED="\033[1;31m"
E_GREEN="\033[1;32m"
E_NO_COLOR="\033[0m"

P_RED=$(tput setaf 1)
P_GREEN=$(tput setaf 2)
P_NO_COLOR=$(tput sgr0)

LIB_MOZ="/opt/mozjpeg/bin/"

PACKAGE="optimizeImage"
VERSION="0.0.1"
WEBSITE="https://github.com/jmcollin"
DATE=`date +%Y`

SOURCE_DIR=""
TMP_DIR="/tmp/${PACKAGE}/"

VERBOSE=""
ALREADYSETTYPE="0"
ALREADYSETQUALITY="0"


####################################################
## Functions

# Display message with color
displayStatusMessage ()
{
	local msg="$1"
	local status="$2"
	local extra="$3 "
	local statuscolor
	if [[ $status == *"OK"* ]]; then
		statuscolor="[${P_GREEN}✔${P_NO_COLOR}] ${msg} ${extra}"
	elif [[ $status == *"FAIL"* ]]; then
		statuscolor="[${P_RED}✘${P_NO_COLOR}] ${msg} ${extra}"
	else
		statuscolor="${msg} ${extra}"
	fi
	printf "%s\n" "$statuscolor"
}

# Display version message
displayVersion ()
{
	echo "${PACKAGE}  version ${VERSION}"
	echo "Copyright © 2014-${DATE} by Jean-Marie Collin."
	echo "Web site: ${WEBSITE}"
	echo " "
	echo "${PACKAGE} comes with ABSOLUTELY NO WARRANTY.  This is free software, and you"
	echo "are welcome to redistribute it under certain conditions.  See the GNU"
	echo "General Public Licence for details."
}

# Display help message
displayHelp ()
{
	displayVersion
	echo " "
	echo "${PACKAGE} allow you to optimize and compress your images in batches"
	echo " "
	echo "Usage: ${PACKAGE} [OPTION]... SRC... DEST"
	echo "  or   ${PACKAGE} [OPTION]... SRC... [DEST]"
	echo " "
	echo "Options"
	echo " -q 90, --quality 90         set quality (default ~ 90)"
	echo " -t jpg, png, gif            set image type (default ~ jpg)"
	echo " "
	#echo " -i                          interactive mode"
	echo " -d                          print dependencies"
	echo " --version                   print version number"
	echo "(-h|-?) --help               show this help (-h is --help only if used alone)"
	echo " "
	checkDependency
}

# Display the Weight of a file
displayWeight ()
{
	local dirs="$1"
	local type="$2"
	local size=`find ${dirs} -type f -name "*.${type}" -ls | awk '{total += $7} END {print total}'`
	echo "$size" | awk '{ split( "o KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ }  printf("%.2f %s\n", $1, v[s]) }'
}

# Check execution of a command
checkCmd ()
{
	local extra="$3 "
	$1 > /dev/null 2>&1

	local result="$?"

	if [ "$result" -eq "0" ] || [ "$result" -eq "1" ]; then
		displayStatusMessage "$2" OK "$extra"
	elif [ "$result" -eq "127" ]; then
		displayStatusMessage "$2" FAIL "$extra"
	else
		displayStatusMessage "$2" FAIL "$extra"
	fi
}

# Check dependency
checkDependency ()
{
	echo "Check dependencies for ${PACKAGE}"
	# checkCmd "identify" "Check identify..."
	checkCmd "pngquant -h" "Check pngquant..."
	checkCmd "pngcrush -h" "Check pngcrush..."
	checkCmd "${LIB_MOZ}jpegtran -h" "Check jpegtran..."
	checkCmd "${LIB_MOZ}djpeg -h" "Check djpeg..."
	checkCmd "${LIB_MOZ}cjpeg -h" "Check cjpeg..."
}

# Check mine type of a file
checkMimeType ()
{
	local space=`echo "$1" | awk --field-separator=" " "{ print NF+1 }"`
	file --mime-type "$1" | awk -v r=$space '{type = $r} END {print type}'
}

# Check filesize
checkFileSize ()
{
	stat -c%s "$1"
}

# Check file dimension
checkImageDimension ()
{
	local space=`echo "$1" | awk --field-separator=" "`
	identify "$1" | awk -v r=$space '{dimension = $r} END {print dimension}'
}

setQuality ()
{
	quality=$1
	re='^[0-9]+$'
	if ! [[ $quality =~ $re ]] ; then
		quality=90
	fi

	if [[ "${quality}" == "" ]]; then
		quality=90
	fi
	echo "${quality}"
}

# Set quality (particularly for jpeg)
setType ()
{
	types=$1
	if [[ "${types}" == "png" ]]; then
		types="png"
	elif [[ "${types}" == "gif" ]]; then
		types="gif"
	elif [ "${types}" == "jpeg" ] || [ "${types}" == "jpeg" ]; then
		types="jpg"
	elif [ "${types}" == "" ] || [ "${types}" != "jpeg" ] || [ "${types}" != "jpeg" ] || [ "${types}" != "png" ] || [ "${types}" == "gif" ]; then
		types="jpg"
	fi
	echo "${types}"
}

# Set source directory
setSource ()
{
	SOURCE_DIR=$1
	echo "${SOURCE_DIR}"
}

# Set tmp directory
setOutput ()
{
	TMP_DIR=$1
	echo "${TMP_DIR}"
}

# Delete temporary file
cleanUp ()
{
	local dirs=${TMP_DIR}
	if [ -d "${dirs}" ]; then
		local nb_file=`ls ${dirs} | wc -l`

		if [[ "$nb_file" -gt "0" ]]; then
			checkCmd "rm -fr ${dirs}*" "Clean directory" "${nb_file} file(s)"
		else
			displayStatusMessage "Clean directory" "${nb_file} file(s)"
		fi
		echo ''
	fi
}

pngOptimize ()
{
	local file="$1"
	local filename=$(basename "${file}")
	png=`pngquant --speed 1 -f 128 -o /tmp/tmp_img_file.png "${file}"`
	png=`pngcrush -brute -ow /tmp/tmp_img_file.png > /dev/null 2>&1`
	checkCmd "${png}" "${file}"
	mv -f /tmp/tmp_img_file.png "${TMP_DIR}${file}"
}

jpgOptimize ()
{
	local file="$1"
	local quality="$2"
	local filename=$(basename "${file}")
	# local dimension=`checkImageDimension ${file}`

	jpg=`${LIB_MOZ}jpegtran -copy none -optimize -progressive -perfect -trim  "${file}" > oojs-opt.jpg`
	jpg=`${LIB_MOZ}djpeg -fast "${file}" | ${LIB_MOZ}cjpeg -quality ${quality} -progressive -noovershoot oojs-opt.jpg > oojs-opt2.jpg`
	checkCmd "${jpg}" "${file}"
	mv -f oojs-opt2.jpg "${TMP_DIR}${filename}"
	rm -f oojs-opt*
}

gifOptimize ()
{
	local file="$1"
	local filename=$(basename "${file}")
	gif=`gifsicle -w -O3 -i ${file} -o /tmp/tmp_img_file.gif && mv -f /tmp/tmp_img_file.gif "${TMP_DIR}${filename}"`
	checkCmd "${gif}" "${file}"
}

optimizeImage ()
{
	local types=$1
	local quality=$2
	local find_number=$(find ${SOURCE_DIR} -name "*.${types}" -ls | wc -l)

	if [ "${find_number}" -lt "1" ]; then
		echo "There is no image to optimize in this directory"
		exit 0
	else

		# Clean tmp directory
		cleanUp

		# Create tmp dir
		mkdir -p "${TMP_DIR}"

		cd "${SOURCE_DIR}"

		echo "Optipmize image(s)"

		if [[ ${types} == "gif" ]]; then
			find . -name '*.gif' | while read LINE;
			do
				local mime=`checkMimeType "${LINE}"`
				local size=`checkFileSize "${LINE}"`
				local file="${LINE}"
				local filename=${LINE//'./'/''}
				local dirname=$(dirname "${LINE}")

				mkdir -p "${TMP_DIR}${dirname}"

				if [[ "$size" -gt "0" ]]; then
					if [[ $mime == "image/png" ]]; then
						pngOptimize "${file}"
					elif [[ $mime == "image/jpeg" ]]; then
						jpgOptimize "${file}" "${quality}"
					elif [[ $mime == "image/gif" ]]; then
						gifOptimize "${file}"
					fi

					# Move file after optimize and resize
					# if [[ -f "${t}${filename}" ]]
					# then
					# 	if [[ "$size_new" -lt "$size" ]]; then
					# 		mv -f ${t}${filename} ${s}${filename}
					# 	fi
					# fi
				else
					displayStatusMessage "${file}name" FAIL "(size ${size})"
				fi
			done
		elif [[ ${types} == "png" ]]; then
			find . -name '*.png' | while read LINE;
			do
				local mime=`checkMimeType "${LINE}"`
				local size=`checkFileSize "${LINE}"`
				local file="${LINE}"
				local filename=${LINE//'./'/''}
				local dirname=$(dirname "${LINE}")

				mkdir -p "${TMP_DIR}${dirname}"

				if [[ "$size" -gt "0" ]]; then
					if [[ $mime == "image/png" ]]; then
						pngOptimize "${file}"
					elif [[ $mime == "image/jpeg" ]]; then
						jpgOptimize "${file}" "${quality}"
					elif [[ $mime == "image/gif" ]]; then
						gifOptimize "${file}"
					fi

					# Move file after optimize and resize
					# if [[ -f "${t}${filename}" ]]
					# then
					# 	if [[ "$size_new" -lt "$size" ]]; then
					# 		mv -f ${t}${filename} ${s}${filename}
					# 	fi
					# fi
				else
					displayStatusMessage "${file}name" FAIL "(size ${size})"
				fi
			done
		elif [[ ${types} == "jpg" ]]; then
			find . -name '*.jpg' | while read LINE;
			do
				local mime=`checkMimeType "${LINE}"`
				local size=`checkFileSize "${LINE}"`
				local file="${LINE}"
				local filename=${LINE//'./'/''}
				local dirname=$(dirname "${LINE}")

				mkdir -p "${TMP_DIR}${dirname}"

				if [[ "$size" -gt "0" ]]; then
					if [[ $mime == "image/png" ]]; then
						pngOptimize "${file}"
					elif [[ $mime == "image/jpeg" ]]; then
						jpgOptimize "${file}" "${quality}"
					elif [[ $mime == "image/gif" ]]; then
						gifOptimize "${file}"
					fi

					# Move file after optimize and resize
					# if [[ -f "${t}${filename}" ]]
					# then
					# 	if [[ "$size_new" -lt "$size" ]]; then
					# 		mv -f ${t}${filename} ${s}${filename}
					# 	fi
					# fi
				else
					displayStatusMessage "${file}name" FAIL "(size ${size})"
				fi
			done
		fi

		cd "$h"
		echo ''
	fi
}

####################################################
## Main

if [ $# -lt 1 ]; then
	displayHelp
	exit 0
fi

while test $# -gt 0; do
	case "$1" in
			-q|--quality)
				if [ $# -lt 3 ]; then
					displayHelp
					exit 0
				else
					nb_args=$#
					shift
					quality=`setQuality "$1"`
					shift

					if [[ $1 == "-t" ]]; then
						shift
						types=`setType "$1"`
						ALREADYSETTYPE="1"
						shift
					fi

					SOURCE_DIR=`setSource "$1"`
					if [ $# -ge 2 ]; then
						shift
						TMP_DIR=`setOutput "$1"`
					fi
					ALREADYSETQUALITY="1"

					# No source set so exit
					if [[ "${SOURCE_DIR}" == "" ]]; then
						displayHelp
						exit 0
					fi
				fi
			;;
			-t)
				nb_args=$#
				shift
				types=`setType "$1"`
				shift
				ALREADYSETTYPE="1"
			;;
			--version)
				displayVersion
				exit 0
			;;
			-h|--help)
				displayHelp
				exit 0
			;;
			-i)
				# Interactive mode !
				# Todo: allow interactive mode
				#	cleanUP tmp directory ? y|n
				#	Resize image (only jpg) ? y|n
				#	Move file after optimize ? y|n
				echo "TODO: Allow interactive mode"
				exit 0
			;;
			-d)
				displayVersion
				echo " "
				checkDependency
				exit 0
			;;
			*)
				# Set quality
				if [[ "${ALREADYSETQUALITY}" == "0" ]]; then
					quality=`setQuality "$1"`
					SOURCE_DIR=`setSource "$1"`
					if [ $# -ge 2 ]; then
						shift
						TMP_DIR=`setOutput "$1"`
					fi
				fi

				if [[ "${ALREADYSETTYPE}" == "0" ]]; then
					types=`setType "$1"`
					SOURCE_DIR=`setSource "$1"`
					if [ $# -ge 2 ]; then
						shift
						TMP_DIR=`setOutput "$1"`
					fi
				fi

				if [[ "${SOURCE_DIR}" == "" ]]; then
					displayHelp
					exit 0
				fi

				# Check if source exit
				if [ ! -d "${SOURCE_DIR}" ]; then
					echo "${PACKAGE} : cannot access ${SOURCE_DIR}: No such file or directory"
					echo ''
					displayHelp
					exit 127
				fi

				# Get original size
				original_size_format=`displayWeight ${SOURCE_DIR} ${types}`

				# Optimize image
				optimizeImage "${types}" "${quality}"

				# Get compress size
				compress_size_format=`displayWeight ${TMP_DIR} ${types}`

				original_size=`echo ${original_size_format} | awk -F " " 'NR==1 {print $1+0}'`
				compress_size=`echo ${compress_size_format} | awk -F " " 'NR==1 {print $1+0}'`

				# Calcuate % savings
				percent=$(printf '%i %i' ${original_size%.*} ${compress_size%.*} | awk '{pc=(($1-$2)/$1)*100; printf "%.2f", pc}')

				# Show new size
				displayStatusMessage "Original Size: ${original_size_format}" FAIL
				displayStatusMessage "Savings Size: ${compress_size_format}" OK
				displayStatusMessage "% Savings: ${percent}%" OK

				exit 0
			;;
	esac
done
