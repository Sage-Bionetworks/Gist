## This build checking package $PACKAGE version $VERSION_TO_CHECK is downloadable from $RAN
## and installable to multiple platforms.
##
## Parameters
##
## RAN -- http://staging-ran.synapse.org / http://ran.synapse.org
## PACKAGE -- PythonEmbedInR / synapser / synapserutils
## VERSION_TO_CHECK -- 0.3.34
## WINDOWS_LABEL_PREFIX -- window
## RVERS -- for Windows
##

# fail early
set -e

echo "if (available.packages(repos='$RAN')['$PACKAGE','Version'] != '$VERSION_TO_CHECK') { quit(save = 'no', status = 1) }" > test.R
echo "try(remove.packages('$PACKAGE'), silent=T)" >> test.R
echo "install.packages('$PACKAGE', repos=c('$RAN', 'https://cloud.r-project.org'))" >> test.R
echo "library('$PACKAGE')" >> test.R

if [[ $label = $WINDOWS_LABEL_PREFIX* ]]
then
  oldPath=$PATH
  ## build x64 version
  PATH=C:\\Program\ Files\\R\\$RVERS\\bin\\x64
  R --vanilla < test.R

  ## build i386 version version
  PATH=C:\\Program\ Files\\R\\$RVERS\\bin\\i386
  R --vanilla < test.R

  PATH=$oldPath
else
  R --vanilla < test.R
fi

rm test.R
  
