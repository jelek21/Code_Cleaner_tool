#!/usr/bin/env bash

# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null;
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "I’m sorry, 'getopt --test' failed in this environment.";
    exit 1;
fi

# Specifying all the variables
EXTS=(".cpp" ".hpp" ".c" ".h" ".java" ".mat" ".sh" ".css" ".html" ".php");
FOLD="";
PATTERN="";
NEXTS=();
FILES=();
RECURSIVE=false;
VERBOSE=false;
FORCE=false;
BACKUP=true;

# -p to specify a pattern to look for.
# -d to specify a directory.
# -e to add an extension to the list of extensions to work on.
# -E to specify exactly what extensions are to be treated (will not treat any other extensions than those precised here).
# -r to specify recursivity (work on folder and subfolder).
# -v to activate the verbose mode.
# -n to exclude an extension, allows to use the built-in extensions list but without checking a specific exetension.
# -b to disable backup mode, no backup of yout file will be done when working on it. TO USE ONLY IF YOU ARE CONMFIDENT IN YOUR CODE!
# -y to disable warning message. TO USE IF YOU ARE CONFIDENT IN THE PARAMETERS YOU HAVE GIVEN!


help() {
	echo "";
	echo "Code_Cleaner tool deletes from your source code files the lines containing a given pattern.";
	echo "";
	echo "Returns the file modified and a .bkp file which is a backup.";
	echo "";
	echo "usage : Code_Cleaner {-option}";
	echo "";
	echo "options :";
	echo "		-b | --no-backup : Do not make any backup. ONLY USE IF YOU ARE CONFIDENT IN YOUR PATTERN!";
	echo "";
	echo "		-d | --directory : specify the working directory.";
	echo '			usage : Debug_Cleaner -f "Path/to/the/directory"';
	echo "";
	echo "		-e | --add-extensions : specify extensions to add to the already default extensions to work on.";
	echo " 			The default extensions list is : .cpp, .hpp, .c, .h, .java, .mat, .sh, .css, .html, .php";
	echo '			usage : Debug_Cleaner -e (".ext" ".ext2" ...)';
	echo "";
	echo "		-E | --only-extensions : Specify the only extensions to work on";
	echo '			usage : Debug_Cleaner -E (".ext" ".ext2" ...)';
	echo "";
	echo "		-n | --exclude-extensions : Specify extensions to avoid, files with those extensions won't be treated.";
	echo '			usage : Debug_Cleaner -n (".ext" ".ext2" ...)';
	echo "";
	echo "		-p | --pattern : specify the pattern to look for.";
	echo '			usage : Debug_Cleaner -p Debug_pattern';
	echo "";
	echo "		-r | --recursive : Recursive mode, will work on the working directory and subfolders.";
	echo "";
	echo "		-v | --verbose : Verbose mode, will print informations during process";
	echo "";
	echo "		-y | --yes : Do not show warning messages";
	echo "";
	echo "		-h | --help | ? : shows this help message";
	echo "";
	echo "";
	echo "";
	echo " 		SETTINGS :";
	echo " 		If you want to setup a default pattern, please export it in the environment variable: CODE_CLEANER_PATTERN (in your .bashrc file)";
	exit 0;
}

SHORTOPT=p:d:e:E:rvybn:h?;
LONGOPT=pattern:,directory:,add-extensions:,only-extensions:,recursive,verbose,no-backup,exclude-extensions:,help,yes;

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options="$SHORTOPT" --longoptions="$LONGOPT" --name "$0" -- "$@");
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    #  then getopt has complained about wrong arguments to stdout
    exit 1;
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED";

# Options available : 
while true; do
	case "$1" in
		-d|--directory) 
			FOLD=$2;
			shift 2;
			;;
		-p|--pattern)
			PATTERN="$2";
			echo "${PATTERN}";
			shift 2;
			;;
		-e|--add-extensions) 
			EXTS+=("$2");
			shift 2;
			;;
		-E|--only-extensions) 
			EXTS=("$2");
			shift 2;
			;;
		-r|--recursive) 
			RECURSIVE=true;
			shift;
			;;
		-v|--verbose) 
			VERBOSE=true;
			shift;
			;;
		-n|--exclude-extensions) 
			NEXTS+=("$2");
			shift 2;
			;;
		-y|--yes)
			FORCE=true;
			shift;
			;;
		-h|--help|"?") 
			help;
			;;
		-b|--no-backup)
			BACKUP=false;
			shift;
			;;
		--)
            shift;
            break
            ;;
		*)
			echo "An error occured in your arguments, unknown parameter $1";
			exit 2;
			;;
	esac;
done;

# Algorithm start
echo "Welcome in Code_Cleaner tool";

# Check whether a pattern has been defined
if [ -z "${PATTERN}" ] && [ -z "${CODE_CLEANER_PATTERN:-}"]; then
	echo "No pattern set, setting to DEBUG ";
	PATTERN="DEBUG";
fi

# Check whether a default pattern has been defined.
if [ -z "${PATTERN}" ] && [ -n "${CODE_CLEANER_PATTERN:-}"]; then
	if [ "${VERBOSE}" = true]; then echo " Using environment variable CODE_CLEANER_PATTERN : ${CODE_CLEANER_PATTERN} "; fi;
	PATTERN="${CODE_CLEANER_PATTERN}";
fi

# Define folder to pwd if not given
if [ -z "${FOLD}" ]; then
	FOLD=$(pwd);
fi;

# Print recursive info if verbose has been defined
if [ "${RECURSIVE}" = true ] && [ "${VERBOSE}" = true ]; then
	echo "Cleaning will be processed in ${FOLD} and subfolders.";
fi;

# Check whether the directory given is a real folder
if [ ! -d "${FOLD}" ];then
	echo "${FOLD} is not a directory.";
	exit 3;
fi;

# Taking in account the list of extensions to avoid
if [ ${#NEXTS[@]} -ne 0 ]; then
	for ne in "${NEXTS[@]}";
	do
		EXTS=("${EXTS[@]#*"$ne"*}");
	done;
fi

# Create a list of files to work on
for e in "${EXTS[@]}"
do
	if [ "${RECURSIVE}" = true ]; then find "${FOLD}" -type f \( -iname "*"$e"" \) && for i in $(find "${FOLD}" -type f \( -iname "*"$e"" \)); do FILES+=("$i"); done;
	else find "${FOLD}" -maxdepth 1 -type f \( -iname "*"$e"" \) && for i in $(find "${FOLD}" -maxdepth 1 -type f \( -iname "*"$e"" \)); do FILES+=("$i"); done;
	fi;
done;

# If no files have been found, print an error message
if [ ${#FILES[@]} -eq 0 ];then
	echo "There are no files to process with the given extensions";
	exit 4;
fi;


echo "We are going to remove all the lines containing ${PATTERN} in the files of the following extension(s) : ";
echo "${EXTS[@]}";
echo "contained in the following directory: ${FOLD}";
if [ "${RECURSIVE}" = true ]; then echo "and subdirectories."; fi;

if [ ! "$FORCE" = true ];then
	while true; do
	    read -p "Are you sure? Yes [Y/y] or No [N/n]?
note: to avoid this warning, use -y option
" yn;
	    case $yn in
	        [Yy]* ) break;;
	        [Nn]* ) exit 5;;
	        * ) echo "Please answer Y/y or N/n.";;
	    esac;
	done;
fi;

if [ "${VERBOSE}" = true ]; then 
	echo "The files to be treated are :";
	echo "${FILES[@]}";
fi;


for i in "${FILES[@]}"
do
	if [ "${VERBOSE}" = true ]; then echo " Treating $i ..."; fi;
		if [ "${BACKUP}" = true ]; then grep -v "$PATTERN" "$i" > "$i".tmp; mv "$i" "$i".bkp; mv "$i".tmp "$i";
		else grep -v "$PATTERN" "$i" > "$i".tmp; mv "$i".tmp "$i";
	fi;
done;
exit 0;