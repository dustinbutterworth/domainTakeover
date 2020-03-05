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

docker run -v $HOME/.config/subfinder:/root/.config/subfinder -it ice3man/subfinder -d ${TARGET} | tee domains
assetfinder -subs-only ${TARGET} | tee -a domains
amass enum -norecursive -noalts -d ${TARGET} | tee -a domains
# dedup and sort, then remove garbage lines (starting with non-alphaneumeric characters or spaces)
cat domains | sort -u | uniq > domains_dd
sed -i '' '/^[^[:alnum:]]/d' domains_dd
rm -f domains
#subjack
subjack -w domains_dd -t 100 -timeout 30 -ssl -c ~/${DIR}/tool/subjack/fingerprints.json -v 3 | grep -v "Not Vulnerable" | tee takeover
# second, make http/https urls and get response data
# third, find your testing poing from grep/gf , etc...
cat takeover | httprobe | tee hosts ; meg -d 1000 -v / | gf cors > cors
cat takeover | httprobe | tee hosts ; meg -d 1000 -v / | gf s3-buckets > s3-buckets
