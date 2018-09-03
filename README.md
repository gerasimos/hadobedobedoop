# hadobedobedoop

Bash scripts for several Hadoop tasks

Script|Description
---|---
`hdfs-download-dir.sh`|Downloads a complete HDFS directory and validates each individual file's size and MD5 for integrity assessment.
`hive-download-partition.sh`|Downloads a specific Hive table partition from HDFS
`day-loop.sh`|Loops over day, and calls a shell script with custom arguments and `--date` (YYYY-MM-DD) parameter.

## Installation

The scripts are assuming GNU tools. 

### Linux

Should work OOTB.

### OSX

In case you are using Mac OSX, make sure to [brew](https://brew.sh/) install:

```shell
brew install gnu-sed --with-default-names
brew install coreutils
```

and add the following line to `.bash_profile` or `.bashrc` or whatever file you define your `$PATH` in order to use the GNU utlis with their original name and not prefixed with a `g`:

```shell
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
```

### Windows

Not tested.