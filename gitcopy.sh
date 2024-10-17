#!/bin/bash
set -x
# Check if enough arguments are supplied
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --source-repo) SOURCE_REPO="$2"; shift ;;
        --git-org) GIT_ORG="$2"; shift ;;
        --dns) DNS="$2"; shift ;;
        --project) PROJECT="$2"; shift ;;
        --projectid) PROJECTID="$2"; shift ;;
        --region) REGION="$2"; shift ;;
        --group) GROUP="$2"; shift ;;
        --directory) DIRECTORY="$2"; shift;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done
if [ -z "$SOURCE_REPO" ] || [ -z "$GIT_ORG" ]; then
    echo "Missing required arguments"
    echo "Usage: $0 --source-repo <SOURCE_REPO> --git-org <GIT_ORG>"
    exit 1
fi
sleep 10
gcloud auth application-default login
gcloud config set project $PROJECTID
GITHUB_TOKEN=$(gcloud secrets versions access 1 --secret="github-token")

mkdir /root/.ssh

gcloud secrets versions access 1 --secret="clone_ssh" --out-file=/root/.ssh/id_rsa
gcloud secrets versions access 1 --secret="known_hosts" --out-file=/root/.ssh/known_hosts

chmod 600 /root/.ssh/id_rsa
chmod 600 /root/.ssh/known_hosts

# Clone the source repository
git clone git@github.com:meghdo-cloud/$SOURCE_REPO.git
cd $SOURCE_REPO

if [ -n "$GROUP" ] ; then
  GRP_PATH=$(echo "$GROUP" | awk -F. '{for(i=1;i<NF;i++) printf "%s/", $i; printf $NF}')
  OLD_DIR="src/main/java/cloud/meghdo/drizzle"
  NEW_DIR="src/main/java/$GRP_PATH/drizzle"
  find . -path ./.git -prune -o -type f -exec sed -i "s|cloud/meghdo|$GRP_PATH|g" {} +
  find . -path ./.git -prune -o -type f -exec sed -i "s/cloud.meghdo/$GROUP/g" {} +

  if [ -n "$DIRECTORY" ]; then
    mkdir -p "$(dirname "$NEW_DIR")"
    mv "$OLD_DIR" "$NEW_DIR"
  fi
fi



find . -path ./.git -prune -o -type f -exec sed -i "s/meghdo-4567/$PROJECTID/g" {} +
find . -path ./.git -prune -o -type f -exec sed -i "s/meghdo-cloud/$GIT_ORG/g" {} +
find . -path ./.git -prune -o -type f -exec sed -i "s/europe-west1/$REGION/g" {} +
find . -path ./.git -prune -o -type f -exec sed -i "s/meghdo.cloud/$DNS/g" {} +
find . -path ./.git -prune -o -type f -exec sed -i "s/meghdo-cluster/$PROJECT-cluster/g" {} +
find . -path ./.git -prune -o -type f -exec sed -i "s/meghdo\/drizzle/$PROJECT\/drizzle/g" {} +

# Set up Git configuration
git config user.name "Jenkins"
git config user.email "jenkinci@meghdo.cloud"


# Note: The remote URL should be set up in Terraform or separately
# Assuming the remote has already been added for the new repository
git remote remove origin

curl -H "Authorization: token $GITHUB_TOKEN" -d '{"name":"'"$SOURCE_REPO"'","private":true}' https://api.github.com/orgs/$GIT_ORG/repos

git remote add origin https://$GITHUB_TOKEN@github.com/$GIT_ORG/$SOURCE_REPO.git

git add .
git commit -m "Modified keywords and moved to new organization"


git push --set-upstream origin main
# Clean up
cd ..
rm -rf "$SOURCE_REPO"
