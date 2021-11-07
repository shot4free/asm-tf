#!/usr/bin/env bash

SCRIPT_DIR=$(dirname $(readlink -f $0 2>/dev/null) 2>/dev/null || echo "${PWD}/$(dirname $0)")
PROJECT_ID=GOOGLE_PROJECT_ID

# List all subfolders under the environments folder
ENVS="prod"

# List all subfolders under each specific environment folder like prod/gcp prod/aws etc
CLOUDS="gcp"

# Prepare provider in the modules/provider folder to be copied to every resource folder
sed -e s/PROJECT_ID/${PROJECT_ID}/ ${SCRIPT_DIR}/../modules/providers/.provider.tf.tmpl > ${SCRIPT_DIR}/../modules/providers/provider.tf

# Loop through every environment, clouds and resources and prepare provider, vars, backend and remote_states for every resource
for ENV in ${ENVS}
do
    for CLOUD in ${CLOUDS}
    do
        echo -e "Preparing ${ENV} environment in ${CLOUD}..."
        declare -a FOLDERS
        unset FOLDERS
        ANY_FOLDERS=$(ls -d ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/*)    # list of full paths like /scripts/../environments/prod/gcp/fleet
        [[ ${ANY_FOLDERS} ]] && FOLDERS=("${ANY_FOLDERS}")
        echo $FOLDERS
        for FOLDER in ${FOLDERS}
        do
            echo -e "Preparing provider for ${FOLDER##*/}..."
            cp -rf ${SCRIPT_DIR}/../modules/providers/provider.tf ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${FOLDER##*/}/provider.tf
            echo -e "Preparing variables for ${FOLDER##*/}..."
            sed -e s/PROJECT_ID/${PROJECT_ID}/ ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${FOLDER##*/}/.variables.tf.tmpl > \
                ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${FOLDER##*/}/variables.tf
            echo -e "Preparing backend for ${FOLDER##*/}..."
            sed -e s/PROJECT_ID/${PROJECT_ID}/ -e s/ENV/${ENV}/ -e s/CLOUD/${CLOUD}/ -e s/RESOURCE/${FOLDER##*/}/ \
                ${SCRIPT_DIR}/../modules/backends/.backend.tf.tmpl > ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${FOLDER##*/}/backend.tf
            echo -e "Preparing remote_state for ${FOLDER##*/}..."
            sed -e s/PROJECT_ID/${PROJECT_ID}/ -e s/ENV/${ENV}/ -e s/CLOUD/${CLOUD}/ -e s/RESOURCE/${FOLDER##*/}/ \
                ${SCRIPT_DIR}/../modules/backends/.remote_state.tf.tmpl > ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${FOLDER##*/}/remote_state.tf
            for COPYFOLDER in ${FOLDERS}
            do
                echo -e "Copying remote state from $FOLDER to $COPYFOLDER..."
                [[ "${COPYFOLDER}" != "${FOLDER}" ]] && cp -r ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${FOLDER##*/}/remote_state.tf ${SCRIPT_DIR}/../environments/${ENV}/${CLOUD}/${COPYFOLDER##*/}/${ENV}-${CLOUD}-${FOLDER##*/}-remote_state.tf
            done
        done
    done
done
