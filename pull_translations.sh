#!/bin/bash

# Pulls the latest strings from Transifex website
# Tested on Ubuntu 16.10, Windows 10, OS X El Capitan
#
# Prerequisites:
#   1. transifex-client installed [see https://docs.transifex.com/client/installing-the-client]
#   2. API token [see here https://docs.transifex.com/api/introduction]
#   3. The slug for resources in Transifex should be the same as the filename in Android project
#      (eg: the slug for strings.xml should be 'strings' in Transifex resource setting)

# Usage:
# 1. Create a file named 'local_pull_translations.cfg' with required details (sample below)

# SAMPLE OF CONFIG FILE
#-----------------------------------------------------------------------------------------------
## Transifex project name (from Transifex settings -> project url)
#PROJECT='akvo-foundation/akvo-flow-mobile'

## list of languages (es,fr,hi,...) (or empty string to pull all languages)
#LANGUAGES='es,fr,hi,id,km,ne,pt,vi'

## path to the project res folder where the files should be updated
#PROJECT_RES_FOLDER='/home/user/akvo-flow-mobile/app/src/main/res'
#-----------------------------------------------------------------------------------------------

# 2. Run command: sh pull_translations.sh
# 3. The project res folder will be updated with latest translation files from Transifex

# NOTE: Delete auto generated .tx folder whenever any configuration or setting changes

. ./local_pull_translations.cfg

TRANSIFEX_HOST='www.transifex.com'
APP_TRANSIFEX_URL='https://'${TRANSIFEX_HOST}'/'${PROJECT}
RES_FOLDER='res/'
VALUES_FOLDER=${RES_FOLDER}/'values'
TX_FOLDER='.tx'
TRANSLATIONS_FOLDER='translations'

# check config
if [ ! -e "$PROJECT_RES_FOLDER" ]; then
    printf "Error: Project res folder not found. Specify correct path in config file\n"
    printf $PROJECT_RES_FOLDER
    printf "\n"
    exit 1
fi

# if tx config folder does not exist then run initial tx setup
if [ ! -e "$TX_FOLDER" ]; then
    printf "Running initial tx setup\n"
    tx init --host=${TRANSIFEX_HOST}
    tx set --auto-remote ${APP_TRANSIFEX_URL}
fi

# remove previously downloaded files
rm -rf ${TRANSLATIONS_FOLDER}

# pull translation files for all or specified languages
[ -z "${LANGUAGES}" ] && tx pull -a || tx pull -l ${LANGUAGES}

# check if pull command succeeded
if [ ! -e "$TRANSLATIONS_FOLDER" ]; then
    printf "\nError: Pull failed. Check tx config, connectivity, url, etc...\n\n"
    printf "Config information:\n"
    cat ${TX_FOLDER}/config
    exit 1
fi

# change to 'translations' folder which was created by the pull command
cd ${TRANSLATIONS_FOLDER}

# move and rename files to values-<lang-code> folder (eg: pt.xml becomes values-pt/<slug>.xml)
# Note: slug is defined in Transifex settings for source file
for subfolder in * ; do
    for lang_file in ${subfolder}/*.xml ; do
        lang_folder=${VALUES_FOLDER}-$(basename ${lang_file} .xml)
        mkdir -p ${lang_folder}
        mv ${lang_file} ${lang_folder}/${subfolder##*.}.xml
    done
done

# rename Indonesian language folder name as app uses 'in'
mv ${VALUES_FOLDER}-id ${VALUES_FOLDER}-in

# update app's res folder with latest files
rsync -avhu --progress ${RES_FOLDER} ${PROJECT_RES_FOLDER}
