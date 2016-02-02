#!/bin/sh

PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NOCOLOUR='\033[0m'
API='-api'

printf "===> Welcome to ${RED}S3${NOCOLOUR} => the ${RED}S${NOCOLOUR}imple ${RED}S${NOCOLOUR}calatra ${RED}S${NOCOLOUR}ervice Creator \n"
printf "Please choose a name for your project (Something like: ${NOCOLOUR}my-new-useful-api${PURPLE})${NOCOLOUR}\n"
read COMPONENT_NAME
PROJECT_NAME=${COMPONENT_NAME%${API}}
PROJECT_NAME=${PROJECT_NAME//-}

printf "${PURPLE}===> Creating $COMPONENT_NAME on Github... ${NOCOLOUR}\n"
brew install hub
hub --version

rm -rf ${COMPONENT_NAME}
mkdir ${COMPONENT_NAME}
cd ${COMPONENT_NAME}
git init
hub create bbc/${COMPONENT_NAME}

printf "\n${PURPLE}===> Fetching scalatra template for your new project...${NOCOLOUR}\n"
git remote add upstream git@github.com:alinaboghiu/scalatra-skeleton.git
git pull upstream master

mv ScalatraSkeletonStacks.patch ${COMPONENT_NAME}.patch
mv src/main/scala/bbc/cps/scalatraskeleton "src/main/scala/bbc/cps/${PROJECT_NAME}"

LANG=C
grep -rl scalatra-skeleton ./ | xargs sed -i '.bak' "s/scalatra-skeleton/${COMPONENT_NAME}/g"
grep -rl scalatraskeleton ./ | xargs sed -i '.bak' "s/scalatraskeleton/${PROJECT_NAME}/g"
grep -rl scalatraSkeleton ./ | xargs sed -i '.bak' "s/scalatraSkeleton/${PROJECT_NAME}/g"
grep -rl ScalatraSkeleton ./ | xargs sed -i '.bak' "s/ScalatraSkeleton/${PROJECT_NAME}/g"
find . -name "*.bak" -type f -delete

git add .
git commit -m "Initial commit to ${COMPONENT_NAME}"
git push origin master
cd ..
printf "\n${PURPLE}===> Your new repo is ready at ${GREEN}https://github.com/bbc/${COMPONENT_NAME} ${NOCOLOUR}\n\n"

printf "${GREEN}===> Creating cloud formation templates${NOCOLOUR}\n"
rm -rf cps-stacks
git clone git@github.com:bbc/cps-stacks.git && cd cps-stacks
patch -p0 < "../${COMPONENT_NAME}/${COMPONENT_NAME}.patch"
git add src/main/resources/*
git add src/main/scala/bbc/cps/Stacks.scala
git commit -m "[${COMPONENT_NAME}] Main and DNS stacks for new the component${NC}\n"
git push
printf "/n ${GREEN}Created Application Stacks Templates${NOCOLOUR}\n"


printf "\n${PURPLE}===> About to create a new Cosmos component. ${RED}This cannot be undone. ${PURPLE}Continue?${NOCOLOUR} "
read -r -p "[y/n]" response
if [[ ${response} =~ ^([yY][eE][sSpP]|[yY])$ ]]
then
    continue
else
    printf "Thanks for using S3. You can do the rest manually if you change your mind.\n"
    exit
fi

printf "Ok. The default project is ${GREEN}cps${NOCOLOUR}. Would you like to use a different project? "
read -r -p "[y/n]" response
if [[ ${response} =~ ^([yY][eE][sSpP]|[yY])$ ]]
then
    read -r -p "Which project? " COSMOS_PROJECT
    continue
else
    COSMOS_PROJECT="cps"
    continue
fi

COSMOS_PAYLOAD="{\"project_name\": \"${COSMOS_PROJECT}\", \"name\": \"${COMPONENT_NAME}\", \"type\": \"service\"}"
curl --cert /etc/pki/client.p12:client -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d "${COSMOS_PAYLOAD}" https://api.live.bbc.co.uk/cosmos/components/create
wait

sbt -Dcom.ning.http.client.AsyncHttpClientConfig.useProxyProperties=true run

cd ..
rm -rf csp-stacks

printf "/n ${GREEN}Created Application Stacks for your new application${NOCOLOUR}\n"
