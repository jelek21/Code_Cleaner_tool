# Code_Cleaner_tool
A Bash script for cleaning your source code from debug lines

The basic command to use it is `Debug_Cleaner.sh -p Pattern -e (".extension1" ".extension2")`
this will deleette every line containing Pattern in \*.extension1 and \*.extension2
To act in recursive mmode, add -r

-h return the following:
```
Code_Cleaner tool deletes from your source code files the lines containing a given pattern.

Returns the file modified and a .bkp file which is a backup."

usage : Code_Cleaner {-option}"

options :
		-p | --pattern : specify the pattern to look for.
			usage : Debug_Cleaner -p "Debug_pattern"

		-d | --directory : specify the working directory.
			usage : Debug_Cleaner -d "Path/to/the/directory"

		-e | --add-extensions : specify extensions to add to the already default extensions to work on.
			usage : Debug_Cleaner -e (".ext" ".ext2" ...)

		-E | --only-extensions : Specify the only extensions to work on
			usage : Debug_Cleaner -E (".ext" ".ext2" ...)

		-r | --recursive : Recursive mode, will work on the working directory and subfolders.

		-v | --verbose : Verbose mode, will print informations during process

		-n | --exclude-extensions : Specify extensions to avoid, files woth those extensions won't be treated.
			usage : Debug_Cleaner -n {".ext",".ext2",...}

		-b | --no-backup : Do not make any backup.

		-y | --yes : Do not show warning messages
			usage : Debug_Cleaner -y

		-h | --help | ? : shows this help message
```

## CONTRIBUTION
Please do not hesitate and send me any ideas you would have to enhance this tool.
