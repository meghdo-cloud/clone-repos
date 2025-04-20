#!/bin/bash
set -x

# Check if enough arguments are supplied
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --source-org) SOURCE_ORG="$2"; shift ;;
        --source-repo) SOURCE_REPO="$2"; shift ;;
        --source-pid) SOURCE_PID="$2"; shift ;;
        --git-org) GIT_ORG="$2"; shift ;;
        --dns) DNS="$2"; shift ;;
        --project) PROJECT="$2"; shift ;;
        --projectid) PROJECTID="$2"; shift ;;
        --region) REGION="$2"; shift ;;
        --group) GROUP="$2"; shift ;;
        --db-host) DB_HOST="$2"; shift ;;
        --directory) DIRECTORY="$2"; shift;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done
if [ -z "$SOURCE_ORG" ] || [ -z "$SOURCE_REPO" ] || [ -z "$GIT_ORG" ]; then
    echo "Missing required arguments"
    echo "Usage: $0  --source-org <SOURCE_ORG> --source-repo <SOURCE_REPO> --git-org <GIT_ORG>"
    exit 1
fi
sleep 10


set +x
GITHUB_TOKEN=$(< /root/token)
set -x
if [ -z $GITHUB_TOKEN ]; then
 echo "Gihub token empty, aborting"
 exit 1
fi


# Create a temporary directory for the template
TEMP_DIR="template_files"
mkdir -p "$TEMP_DIR"

# Clone only the latest commit and copy files without Git history
git clone --depth 1 https://github.com/$SOURCE_ORG/$SOURCE_REPO.git "$TEMP_DIR"
cd "$TEMP_DIR"
rm -rf .git

if [ -n "$GROUP" ] ; then
  GRP_PATH=$(echo "$GROUP" | awk -F. '{for(i=1;i<NF;i++) printf "%s/", $i; printf $NF}')
  OLD_DIR="src/main/java/cloud/meghdo/drizzle"
  NEW_DIR="src/main/java/$GRP_PATH/drizzle"
  find . -type f -exec sed -i "s|cloud/meghdo|$GRP_PATH|g" {} +
  find . -type f -exec sed -i "s/cloud\.meghdo/$GROUP/g" {} +

  if [ -n "$DIRECTORY" ]; then
    mkdir -p "$(dirname "$NEW_DIR")"
    mv "$OLD_DIR" "$NEW_DIR"
  fi
fi



find . -type f -exec sed -i "s/$SOURCE_PID/$PROJECTID/g" {} +
find . -type f -exec sed -i "s/$SOURCE_ORG/$GIT_ORG/g" {} +
find . -type f -exec sed -i "s/meghdo-instance.ca9m0486s1c6.us-east-1.rds.amazonaws.com/$DB_HOST/g" {} +
find . -type f -exec sed -i "s/europe-west1/$REGION/g" {} +
find . -type f -exec sed -i "s/us-east-1/$REGION/g" {} +
find . -type f -exec sed -i "s/meghdo.cloud/$DNS/g" {} +
find . -type f -exec sed -i "s/meghdo-cluster/$PROJECT-cluster/g" {} +
find . -type f -exec sed -i -E "s/meghdo(-|_)database/$PROJECT\1database/g" {} +
find . -type f -exec sed -i "s/meghdo-instance/$PROJECT-instance/g" {} +
find . -type f -exec sed -i "s/meghdo-ingress-gateway/$PROJECT-ingress-gateway/g" {} +
find . -type f -exec sed -i "s/repository: meghdo\/drizzle/repository: $PROJECT\/drizzle/g" {} +
find . -type f -exec sed -i "s/accountName: \"meghdo\"/accountName: \"$PROJECT\"/g" {} +


# Set up Git configuration
git init
git config user.name "Jenkins"
git config user.email "jenkinci@meghdo.cloud"

WEBHOOK="https://jenkins.$DNS/github-webhook/"
set +x
# create a new repo
curl -H "Authorization: token $GITHUB_TOKEN" -d '{"name":"'"$SOURCE_REPO"'","private":true}' https://api.github.com/orgs/$GIT_ORG/repos
# update the webhook
curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" -X POST \
             -d '{
                    "name": "web",
                    "active": true,
                    "events": ["push", "pull_request"],
                    "config": {
                        "url": "'"$WEBHOOK"'",
                        "content_type": "json",
                        "insecure_ssl": "0"
                    }
                 }' \
             https://api.github.com/repos/$GIT_ORG/$SOURCE_REPO/hooks

git remote add origin https://$GITHUB_TOKEN@github.com/$GIT_ORG/$SOURCE_REPO.git

set -x

git add .
git commit -m "Modified keywords and moved to new organization"
git branch -M main
git push -u origin main
# Clean up
cd ..
rm -rf "$TEMP_DIR"
