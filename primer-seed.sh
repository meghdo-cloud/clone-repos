#!/bin/bash
set -x

# Check if enough arguments are supplied
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --primer-repo) PRIMER_REPO="$2"; shift ;;
        --git-org) GIT_ORG="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

sshUrl="git@github.com:${GIT_ORG}/${PRIMER_REPO}.git"
set +x
GITHUB_TOKEN=$(< /root/token)
if [ -z $GITHUB_TOKEN ]; then
 echo "Gihub token empty, aborting"
 exit 1
fi
# check if repo exits
REPO_URL="https://$GITHUB_TOKEN@github.com/${GIT_ORG}/jenkins-jobs.git"

if git ls-remote "$REPO_URL" > /dev/null 2>&1; then
    git clone "$REPO_URL"
else
    echo "Seed Repository does not exist. Exiting."
    exit 1
fi

set -x
echo ${sshUrl} >> ./jenkins-jobs/seed_jobs/gitrepos.txt
cat ./jenkins-jobs/seed_jobs/gitrepos.txt
cd jenkins-jobs/seed_jobs
git config user.email "jenkins@${GIT_ORG}.com"
git config user.name "Jenkins CI"
git add gitrepos.txt
git commit -m "Added ${PRIMER_REPO} repo to gitrepos.txt"
set +x
git push https://$GITHUB_TOKEN@github.com/${GIT_ORG}/jenkins-jobs.git main
set -x

cd ../..
rm -rf jenkins-jobs