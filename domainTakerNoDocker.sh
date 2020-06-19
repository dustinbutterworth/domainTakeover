#!/usr/bin/env bash
# Credit to @hahwul for sharing this on twitter: https://twitter.com/hahwul/status/1228364474282733568
# Prerequisites:
# https://github.com/projectdiscovery/subfinder
# https://github.com/tomnomnom/assetfinder
# https://github.com/OWASP/Amass
# https://github.com/haccer/subjack
# https://github.com/tomnomnom/httprobe
# https://github.com/tomnomnom/gf
# https://github.com/tomnomnom/meg

# Vars
echo "Target Domain?"
read TARGET

if [ -d "${TARGET}" ] 
then
    printf "#######################################################\n"
    echo "${TARGET} directory exists."
    printf "#######################################################\n\n\n"
else
    mkdir ${TARGET}
    printf "#######################################################\n"
    echo "Created ${TARGET} directory."
    printf "#######################################################\n\n\n"
fi

# I want to get the output of each tool separately, but also add all the outputs to one big combined file.

if ! [ -x "$(command -v subfinder)" ]
then
    echo 'Error: subfinder is not installed.' >&2
    exit 1
else
    printf "#######################################################\n"
    echo "Running Subfinder against ${TARGET}"
    printf "#######################################################\n\n\n"
    touch ./${TARGET}/subfinder.out
    subfinder -silent -d ${TARGET} | tee ./${TARGET}/subfinder.out
    cat ./${TARGET}/subfinder.out > ./${TARGET}/domains
    printf "#######################################################\n"
    echo "Subfinder has finished with ${TARGET}"
    printf "#######################################################\n\n\n"
fi

if ! [ -x "$(command -v assetfinder)" ]
then
    echo 'Error: Assetfinder is not installed or not in path.' >&2
    exit 1
else
    printf "#######################################################\n"
    echo "Running Assetfinder against ${TARGET}"
    printf "#######################################################\n\n\n"
    assetfinder -subs-only ${TARGET} | tee ./${TARGET}/assetfinder.out
    cat ./${TARGET}/assetfinder.out >> ./${TARGET}/domains
    printf "#######################################################\n"
    echo "Assetfinder has finished with ${TARGET}"
    printf "#######################################################\n\n\n"
fi

if ! [ -x "$(command -v amass)" ]
then
    echo 'Error: amass is not installed or not in path.' >&2
    exit 1
else
    printf "#######################################################\n"
    echo "Running Amass against ${TARGET}"
    printf "#######################################################\n\n\n"
    amass enum -norecursive -noalts -d ${TARGET} | tee ./${TARGET}/amass.out
    cat ./${TARGET}/amass.out >> ./${TARGET}/domains
    printf "#######################################################\n"
    echo "Amass has finished with ${TARGET}"
    printf "#######################################################\n\n\n"
fi

# dedup and sort, remove garbage chars, then remove garbage lines (starting with non-alphaneumeric characters or spaces)
printf "#######################################################\n"
echo "Deduping, sorting, removing nasty characters..."
printf "#######################################################\n\n\n"
sed -e "s///" ./${TARGET}/domains > ./${TARGET}/domains_nochars
cat ./${TARGET}/domains_nochars | sort -u | uniq > ./${TARGET}/domains_dd
sed -i '' '/^[^[:alnum:]]/d' ./${TARGET}/domains_dd
rm -f ./${TARGET}/domains
rm -f ./${TARGET}/domains_nochars
printf "#######################################################\n"
echo "Finished Deduping, sorting, and removing nasty characters."
printf "#######################################################\n\n\n"

#subjack
if ! [ -x "$(command -v subjack)" ]
then
    echo 'Error: Subjack is not installed or not in path.' >&2
    exit 1
else
    printf "#######################################################\n"
    echo "Running Subjack against ${TARGET}"
    printf "#######################################################\n\n\n"
    subjack -w ./${TARGET}/domains_dd -t 100 -timeout 30 -ssl -c ./fingerprints.json -v 3 | grep -v "Not Vulnerable" | tee ./${TARGET}/takeover
    printf "#######################################################\n"
    echo "Subjack has finished with ${TARGET}"
    printf "#######################################################\n\n\n"
fi

# second, make http/https urls and get response data
# third, find your testing poing from grep/gf , etc...
if ! [ -x "$(command -v meg)" ]
then
    echo 'Error: meg is not installed or not in path.' >&2
    exit 1
fi 

if ! [ -x "$(command -v gf)" ]
then
    echo 'Error: gf is not installed or not in path.' >&2
    exit 1
fi 

if ! [ -x "$(command -v httprobe)" ]
then
    echo 'Error: Httprobe is not installed or not in path.' >&2
    exit 1
else
    printf "#######################################################\n"
    echo "Running httprobe against ${TARGET}"
    printf "#######################################################\n\n\n"
    cat ./${TARGET}/domains_dd | httprobe | tee ./${TARGET}/httprobe.out
    meg -d 1000 -v / ./${TARGET}/httprobe.out ./${TARGET}/meg.out | tee ./${TARGET}/megresults.out
    gf cors ./${TARGET}/meg.out | tee ./${TARGET}/cors
    gf s3-buckets ./${TARGET}/meg.out | tee ./${TARGET}/s3-buckets
    cat ./${TARGET}/cors | sort -u | uniq > ./${TARGET}/cors_dd
    cat ./${TARGET}/s3-buckets | sort -u | uniq > ./${TARGET}/s3-buckets_dd
    mv ./${TARGET}/cors_dd ./${TARGET}/cors
    mv ./${TARGET}/s3-buckets_dd ./${TARGET}/s3-buckets
    printf "#######################################################\n"
    echo "Httpprobe has finished with ${TARGET}"
    printf "#######################################################\n\n\n"
fi

echo "DONE"
