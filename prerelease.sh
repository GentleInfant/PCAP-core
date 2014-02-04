#!/bin/bash

set -eu # exit on first error or undefined value in subtitution

# get current directory
INIT_DIR=`pwd`

# get location of this file
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  echo Failed to determine location of script >2
  exit 1  # fail
fi
# change into the location of the script
cd $MY_PATH

echo '### Running perl tests ###'

export HARNESS_PERL_SWITCHES=-MDevel::Cover=-db,reports,-ignore,'t/.*\.t'
rm -rf reports reports_text reports_html
mkdir reports_text
prove --nocolor -I ./lib | sed 's/^/  /' # indent output of prove
if [[ $? -ne 0 ]] ; then
  echo "\n\tERROR: TESTS FAILED\n"
  exit 1
fi
cover -coverage branch,condition,subroutine,pod -report html_basic reports -silent > /dev/null
cover -coverage branch,condition,subroutine,pod -report text reports -silent > reports_text/coverage.txt
rm -rf reports/structure reports/digests reports/cover.13 reports/runs
mv reports reports_html
cp reports_html/coverage.html reports_html/index.html
unset HARNESS_PERL_SWITCHES

echo '### Generating POD ###'
mkdir -p docs
perl -MPod::Simple::HTMLBatch -e 'Pod::Simple::HTMLBatch::go' lib:bin docs/ > /dev/null

# generate manifest, and cleanup
echo '### Generating MANIFEST ###'
# delete incase any files are moved, the make target just adds stuff
rm -f MANIFEST
./Makefile.PL > /dev/null
make manifest &> /dev/null
rm -f Makefile MYMETA.json MYMETA.yml MANIFEST.bak

# change back to original dir
cd $INIT_DIR
