#!/bin/bash
#
# Script to run Python 3 end-to-end tests on a Linux Jenkins instance.
#
# This file is generated by l2tdevtools update-dependencies.py.

# Fail on error.
set -e

CONFIGURATION_NAME=$$1;

CONFIGURATION_FILE="$${CONFIGURATION_NAME}.ini";

SOURCES_DIRECTORY="/media/greendale_images";
REFERENCES_DIRECTORY="/media/greendale_images";

RESULTS_DIRECTORY="${project_name}-out";

# Change path to test this script on CI system.
if test $${CONFIGURATION_NAME} = 'ci';
then
	SOURCES_DIRECTORY="test_data";
	REFERENCES_DIRECTORY="test_data/end_to_end";
	CONFIGURATION_FILE="config/jenkins/$${CONFIGURATION_NAME}.ini";
fi

mkdir -p $${RESULTS_DIRECTORY} $${RESULTS_DIRECTORY}/profiling;

if ! test -f $${CONFIGURATION_FILE};
then
	CONFIGURATION_FILE="config/jenkins/greendale/$${CONFIGURATION_NAME}.ini";
fi
if ! test -f $${CONFIGURATION_FILE};
then
	CONFIGURATION_FILE="config/jenkins/sans/$${CONFIGURATION_NAME}.ini";
fi
if ! test -f $${CONFIGURATION_FILE};
then
	CONFIGURATION_FILE="config/jenkins/other/$${CONFIGURATION_NAME}.ini";
fi

PYTHONPATH=. python3 ./utils/check_dependencies.py

# Start the end-to-end tests in the background so we can capture the PID of
# the process while the script is running.
PYTHONPATH=. python3 ./tests/end-to-end.py --config $${CONFIGURATION_FILE} --sources-directory $${SOURCES_DIRECTORY} --scripts-directory ${scripts_directory} --results-directory $${RESULTS_DIRECTORY} --references-directory $${REFERENCES_DIRECTORY} &

PID_COMMAND=$$!;

echo "End-to-end tests started (PID: $${PID_COMMAND})";

wait $${PID_COMMAND};

RESULT=$$?;

# On CI system print the stdout and stderr output to troubleshoot potential issues.
if test $${CONFIGURATION_NAME} = 'ci';
then
	for FILE in $$(find $${RESULTS_DIRECTORY} -name \*.out -type f);
	do
		echo "stdout file: $${FILE}";
		cat $${FILE};
		echo "";
	done

	for FILE in $$(find $${RESULTS_DIRECTORY} -name \*.err -type f);
	do
		echo "stderr file: $${FILE}";
		cat $${FILE};
		echo "";
	done
fi

exit $${RESULT};
