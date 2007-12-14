#!/bin/sh -
PLUGINS_REPOSITORY_URL=http://blacktree-elements-public.googlecode.com/svn

cd ${QS_PLUGINS_FOLDER}

echo "warning: $0 : getting plugin list from ${PLUGINS_REPOSITORY_URL}, please wait..."
for plugin in `svn list ${PLUGINS_REPOSITORY_URL} | sed -e "s#/##"`; do
    if [ ! -e ${plugin} ]; then
        echo "warning: $0 : ${plugin} missing: checking out from ${PLUGINS_REPOSITORY_URL}/${plugin}/trunk"
        svn co ${PLUGINS_REPOSITORY_URL}/${plugin}/trunk ${plugin}
    else
        echo "warning: $0 : ${plugin} exists: skipping"
    fi
done