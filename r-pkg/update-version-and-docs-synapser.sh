# This script is used for synapser_staging_artifact. 
# It checkout REPO_NAME repository, changes the version, update the docs, and push the changes back to the repository.

# Params
# USERNAME -- Github user who is running this build
# GITHUB_TOKEN -- The Github token that grants access to GITHUB_ACCOUNT for USERNAME
# USER_EMAIL -- The email of the USERNAME above
# GITHUB_ACCOUNT -- The target Github account
# REPO_NAME -- The repository to update
# BRANCH -- The branch to push update to
# RAN -- The R Archive Network URL to download synapser dependencies (PythonEmbedInR)
# SYN_USERNAME -- The Synapse creds that is used to build vignettes
# SYN_APIKEY -- The Synapse creds that is used to build vignettes
# SYNAPSE_BASE_ENDPOINT -- The dev-stack that is used to build vignettes

# remove the last build clone
set +e
rm -R ${REPO_NAME}
set -e

# clone/pull the github repo
git clone https://github.com/${GITHUB_ACCOUNT}/${REPO_NAME}.git
# https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/

cd ${REPO_NAME}

git remote add upstream https://${USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_ACCOUNT}/${REPO_NAME}.git
git config user.name "${USERNAME}"
git config user.email "${USER_EMAIL}"

git fetch upstream
git checkout -b ${BRANCH} upstream/${BRANCH}

# replace DESCRIPTION with $VERSION
VERSION_LINE=`grep Version DESCRIPTION`
sed "s|$VERSION_LINE|Version: $VERSION|g" DESCRIPTION > DESCRIPTION.temp

# replace DESCRIPTION with $DATE
DATE=`date +%Y-%m-%d`
DATE_LINE=`grep Date DESCRIPTION.temp`
sed "s|$DATE_LINE|Date: $DATE|g" DESCRIPTION.temp > DESCRIPTION2.temp

rm DESCRIPTION
mv DESCRIPTION2.temp DESCRIPTION
rm DESCRIPTION.temp

# replace man/synapser-package.Rd with $VERSION
VERSION_LINE=`grep Version man/synapser-package.Rd`
sed "s|$VERSION_LINE|Version: $VERSION|g" man/synapser-package.Rd > man/synapser-package.Rd.temp

# replace man/synapser-package.Rd with $DATE
DATE=`date +%Y-%m-%d`
DATE_LINE=`grep Date man/synapser-package.Rd.temp`
sed "s|$DATE_LINE|Date: $DATE|g" man/synapser-package.Rd.temp > man/synapser-package.Rd2.temp

rm man/synapser-package.Rd
mv man/synapser-package.Rd2.temp man/synapser-package.Rd
rm man/synapser-package.Rd.temp

# add a directory that we can write to
set +e
rm -rf ../RLIB
set -e
mkdir -p ../RLIB

R -e ".libPaths(c('../RLIB', .libPaths()));\
install.packages(c('fs', 'pack', 'R6', 'testthat', 'knitr', 'rmarkdown', 'PythonEmbedInR', 'pkgdown'),\
 repos=c('https://cloud.r-project.org', '${RAN}'))"

# need to build the package to be able to build docs
## build the package, including the vignettes
R CMD build ./ --no-build-vignettes

## now install it, creating the deployable archive as a side effect
R CMD INSTALL ./ --library=../RLIB

# add Synapse configuration to build vignettes
# store the login credentials
echo "[authentication]" > orig.synapseConfig
echo "username=${SYN_USERNAME}" >> orig.synapseConfig
echo "password=${SYN_PASSWORD}" >> orig.synapseConfig
# store synapse base endpoint
echo "[endpoints]" >> orig.synapseConfig
echo "repoEndpoint=${SYNAPSE_BASE_ENDPOINT}/repo/v1" >> orig.synapseConfig
echo "authEndpoint=${SYNAPSE_BASE_ENDPOINT}/auth/v1" >> orig.synapseConfig
echo "fileHandleEndpoint=${SYNAPSE_BASE_ENDPOINT}/file/v1" >> orig.synapseConfig

# Mac OS settings
set +e
rm -rf ~/.synapseCache
set -e
mv orig.synapseConfig ~/.synapseConfig

# clean up the docs folder before building a new site
set +e
rm -rf docs/
set -e

R -e ".libPaths(c('../RLIB', .libPaths()));\
library(rmarkdown);\
if (pandoc_available())\
  cat('pandoc', as.character(pandoc_version()), 'is available.');\
pkgdown::build_site(document = FALSE, lazy = TRUE, preview = FALSE, new_process = FALSE)"

## clean up the temporary R library dir
rm -rf ../RLIB

# keep CNAME settings
git update-index --assume-unchanged docs/CNAME
git add --all
git commit -m "Version $VERSION is succesfully built on $DATE"
git push upstream ${BRANCH}

git tag $VERSION
git push upstream $VERSION

cd ..
rm -rf ${REPO_NAME}

