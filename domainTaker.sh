#!/usr/bin/env bash
# Credit to @hahwul for sharing this on twitter: https://twitter.com/hahwul/status/1228364474282733568
# Pre-requsites:
# https://github.com/projectdiscovery/subfinder
# https://github.com/tomnomnom/assetfinder
# https://github.com/OWASP/Amass
# https://github.com/haccer/subjack
# https://github.com/tomnomnom/httprobe
# https://github.com/tomnomnom/gf
# https://github.com/tomnomnom/meg

# Vars
DIR="github/domainTaker"
echo "Target Domain?"
read TARGET

mkdir ${TARGET}
docker run -v $HOME/.config/subfinder:/root/.config/subfinder -it ice3man/subfinder -d ${TARGET} | tee ./${TARGET}/domains
assetfinder -subs-only ${TARGET} | tee -a ./${TARGET}/domains
amass enum -norecursive -noalts -d ${TARGET} | tee -a ./${TARGET}/domains
# dedup and sort, then remove garbage lines (starting with non-alphaneumeric characters or spaces)
cat ./${TARGET}/domains | sort -u | uniq > ./${TARGET}/domains_dd
sed -i '' '/^[^[:alnum:]]/d' ./${TARGET}/domains_dd
rm -f ./${TARGET}/domains
#subjack
subjack -w ./${TARGET}/domains_dd -t 100 -timeout 30 -ssl -c ~/${DIR}/tool/subjack/fingerprints.json -v 3 | grep -v "Not Vulnerable" | tee ./${TARGET}/takeover
# second, make http/https urls and get response data
# third, find your testing poing from grep/gf , etc...
cat ./${TARGET}/takeover | httprobe | tee hosts ; meg -d 1000 -v / hosts | gf cors > ./${TARGET}/cors
cat ./${TARGET}/takeover | httprobe | tee hosts ; meg -d 1000 -v / hosts | gf s3-buckets > ./${TARGET}/s3-buckets
