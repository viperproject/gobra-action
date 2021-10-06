#!/bin/bash

RESULT=0
NUMBER_OF_PACKAGES_VERIFIED=0
NUMBER_OF_FAILED_PACKAGE_VERIFICATIONS=0
NUMBER_OF_TIMEOUT_PACKAGE_VERIFICATIONS=0
for gobraPackage in $PACKAGES
do
    CMDARG="$(find $gobraPackage/*.gobra 2> /dev/null | xargs)"
    if [ -n "$CMDARG" ]; then
	echo -e "${YELLOW}Verifying package $gobraPackage${RESET}"
	NUMBER_OF_PACKAGES_VERIFIED=$[ $NUMBER_OF_PACKAGES_VERIFIED+1 ]
	if timeout "$INPUT_PACKAGETIMEOUT" sh -c "java -Xss$INPUT_JAVAXSS -Xmx$INPUT_JAVAXMX -jar $GOBRA_JAR -i $CMDARG -I $PROJECT_LOCATION"; then
            echo -e "${GREEN} $gobraPackage successfully verified${RESET}"
        else
	    if [ $? -eq 124 ]; then
		NUMBER_OF_TIMEOUT_PACKAGE_VERIFICATIONS=$[ $NUMBER_OF_TIMEOUT_PACKAGE_VERIFICATIONS+1 ]
		echo -e "${RED}Verification of package $gobraPackage timed out${RESET}"
	    else
	      	NUMBER_OF_FAILED_PACKAGE_VERIFICATIONS=$[ $NUMBER_OF_FAILED_PACKAGE_VERIFICATIONS+1 ]
		echo -e "${RED}Verification error in package $gobraPackage${RESET}"
	    fi
	    RESULT=$[ $RESULT+1 ]
        fi
    fi
done

echo $NUMBER_OF_PACKAGES_VERIFIED > output_num_packages
echo $NUMBER_OF_FAILED_PACKAGE_VERIFICATIONS > output_num_failed_packages
echo $NUMBER_OF_TIMEOUT_PACKAGE_VERIFICATIONS > output_num_timeout_packages

exit $RESULT;
