#!/bin/bash


## ~~~~~~~~~~~~~~~~~~~~~~~~~ DO NOT CHANGE ~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##                      ______________________                        ##


if [ $# -eq 0 ] || [ -z "$1" ]
  then
    echo "ERROR: Not all mandatory arguments supplied, please supply environment and/or job arguments"
    echo
    echo "Usage: initialise-repo.sh ..."
    echo "Creates a basic folder structure for a Pentaho code or config repository"
    echo 
    echo "Mandatory arguments"
    echo
    echo "-a   PSGRS_ACTION: Choose number"
    echo "        (1) Project Repo with Common Config and Modules"
    echo "        (2) Standalone Project and Config (No Common Artefacts)"
    echo "        pdi_module"
    echo "        pdi_module_repo"
    echo "        project_code"
    echo "        project_config"
    echo "        standalone_project_config"
    echo "        common_code"
    echo "        common_config"
    echo "        project_docu"
    echo "        common_docu"
    echo " "
    echo "Mandatory arguments:"
    echo " "
    echo "-g  GROUP NAME:    Full Project Name, e.g. world-wide-trading"
    echo "                   Lower case, only letters allowed, no underscores, dashes etc."
    echo "                   Minimum of 3 to a maximum of 20 letters."
    echo "-p  PROJECT NAME:  Project name abbreviation, e.g. wwt"
    echo "                   Lower case, only letters allowed, no underscores, dashes etc."
    echo "                   Minimum of 3 to a maximum of 20 letters."
    echo "-e  ENVIRONMENT:   Name of the environment: dev, test, prod or similiar. "
    echo "                   Lower case, only letters allowed, no underscores, dashes etc"
    echo "                   Minimum of 3 to a maximum of 10 letters."
    echo "-s  STORAGE TYPE:  Which type of PDI storage type to use."
    echo "                   Possible values: file-based, file-repo. Not supported: db-repo, ee-repo"
    echo "                   File-repo is only partially supported. You will have to create your own modules/wrapper jobs."
    echo "-w  WEB-SPOON:     Optional. If you intend to run everything within a WebSpoon Docker container."
    echo "                   For now only relevant if you use the file-based PDI repository."
    echo "                   Using this option means config won't work outside the container!"
    echo "                   Possible values: yes"
    echo ""
    echo "Sample usage:"
    echo "initialise-repo.sh -a 1 -g mysampleproj -p msp -e dev -s file-based"
    echo "initialise-repo.sh -a 1 -g mysampleproj -p mys -e dev -s file-repo -w yes"
    echo "initialise-repo.sh -a 2 -g mysampleproj -p msp -e dev -s file-based"
    echo "initialise-repo.sh -a standalone_project_config -g mysampleproj -p msp -e dev -s file-based"
    echo ""
    echo "exiting ..."
    exit 1
fi

while getopts ":a:g:p:e:s:w:" opt; do
  case $opt in
    a) PSGRS_ACTION="$OPTARG"
        echo "Submitted PSGRS_ACTION value: ${PSGRS_ACTION}"
    ;;
    g) export PSGRS_PROJECT_GROUP_NAME="$OPTARG"
        echo "Submitted project name value: ${PSGRS_PROJECT_GROUP_NAME}"
        if [[ ! ${PSGRS_PROJECT_GROUP_NAME} =~ ^[a-z\-]{3,40}$ ]]; then
          echo "Unsupported group name!"
          echo "Lower case, only letters and dashes allowed, no underscores etc."
          echo "Minimum of 3 to a maximum of 40 characters."
          exit 1
        fi
    ;;
    p) export PSGRS_PROJECT_NAME="$OPTARG"
        echo "Submitted project name value: ${PSGRS_PROJECT_NAME}"
        if [[ ! ${PSGRS_PROJECT_NAME} =~ ^[a-z]{3,20}$ ]]; then
          echo "Unsupported project name!"
          echo "Lower case, only letters allowed, no underscores, dashes, spaces etc."
          echo "Minimum of 3 to a maximum of 20 characters."
          exit 1
        fi
    ;;
    e) export PSGRS_ENV="$OPTARG"
        echo "Submitted environment value: ${PSGRS_ENV}" 
        if [[ ! ${PSGRS_ENV} =~ ^[a-z]{3,10}$ ]]; then
          echo "Unsupported environment name!"
          echo "Lower case, only letters allowed, no underscores, dashes, spaces etc."
          echo "Minimum of 3 to a maximum of 10 letters."
          exit 1
        fi
    ;;
    s) PSGRS_PDI_STORAGE_TYPE="$OPTARG"
        echo "Submitted environment value: ${PSGRS_PDI_STORAGE_TYPE}" 
        # check that supplied value is in the list of possible values
        # validate() { echo "files file-repo ee-repo" | grep -F -q -w "${PSGRS_PDI_STORAGE_TYPE}"; }
        LIST_CHECK=$(echo "file-based file-repo ee-repo" | grep -F -q -w "${PSGRS_PDI_STORAGE_TYPE}" && echo "valid" || echo "invalid")
        echo "List check: ${LIST_CHECK}"
        if [ ${LIST_CHECK} = "invalid" ]; then
          echo "Unsupported storage type!"
          echo "Possible values: file-based, file-repo, ee-repo"
          exit 1
        fi
    ;;
    w) PSGRS_PDI_WEBSPOON_SUPPORT="$OPTARG"
        echo "Submitted WebSpoon Support value: ${PSGRS_PDI_WEBSPOON_SUPPORT}" 
    ;;
    \?) 
      echo "Invalid option -$OPTARG" >&2
      exit 1
    ;;
  esac
done

# Example Usage:
# /home/dsteiner/git/pentaho-standardised-git-repo-setup/initialise-repo.sh -a standalone_project_config -g mysampleproj -p mys -e dev -s file-based
# /home/dsteiner/git/pentaho-standardised-git-repo-setup/initialise-repo.sh -a 1 -g mysampleproj -p mys -e dev -s file-based
# /home/dsteiner/git/pentaho-standardised-git-repo-setup/initialise-repo.sh -a 1 -g mysampleproj -p mys -e dev -s file-repo
# /home/dsteiner/git/pentaho-standardised-git-repo-setup/initialise-repo.sh -a 1 -g mysampleproj -p mys -e dev -s file-repo -w yes


# MAIN SCRIPT

PSGRS_WORKING_DIR=`pwd`
PSGRS_SHELL_DIR=$(dirname $0)

# Source config settings
source ${PSGRS_SHELL_DIR}/config/settings.sh


PSGRS_COMMON_GROUP_NAME=${PSGRS_G_COMMON_GROUP_NAME}
# folder that holds the common and project specific repos
# added as there some scripts that sit outside the repos
PSGRS_DEPLOYMENT_FOLDER_NAME=${PSGRS_G_DEPLOYMENT_FOLDER_NAME}
# create top level folder to not pollute any other folder

# make sure group name value is set
if [ -z ${PSGRS_PROJECT_GROUP_NAME} ]; then
  echo "Not all required arguments were supplied. Group Name value missing."
  echo "exiting ..."
  exit 1
fi

# check if directory already exists
# otherwise create it
if [ ! -d "${PSGRS_DEPLOYMENT_FOLDER_NAME}" ]; then
  mkdir ${PSGRS_DEPLOYMENT_FOLDER_NAME}
fi

cd ${PSGRS_DEPLOYMENT_FOLDER_NAME}

if [ ! -d "${PSGRS_COMMON_GROUP_NAME}" ]; then
  mkdir ${PSGRS_COMMON_GROUP_NAME}
fi

if [ ! -d "${PSGRS_PROJECT_GROUP_NAME}" ]; then
  mkdir ${PSGRS_PROJECT_GROUP_NAME}
fi

PSGRS_DEPLOYMENT_DIR=${PSGRS_WORKING_DIR}/${PSGRS_DEPLOYMENT_FOLDER_NAME}
PSGRS_COMMON_GROUP_DIR=${PSGRS_WORKING_DIR}/${PSGRS_DEPLOYMENT_FOLDER_NAME}/${PSGRS_COMMON_GROUP_NAME}
PSGRS_PROJECT_GROUP_DIR=${PSGRS_WORKING_DIR}/${PSGRS_DEPLOYMENT_FOLDER_NAME}/${PSGRS_PROJECT_GROUP_NAME}


echo "===============** PSGRS PATHS **===================="
echo ""
echo "PSGRS SHELL DIR:          ${PSGRS_SHELL_DIR}"
echo "PSGRS_DEPLOYMENT_DIR:     ${PSGRS_DEPLOYMENT_DIR}"
echo "PSGRS COMMON GROUP DIR:   ${PSGRS_COMMON_GROUP_DIR}"
echo "PSGRS PROJECT GROUP DIR:  ${PSGRS_PROJECT_GROUP_DIR}"
echo ""
echo "===================================================="

function pdi_module {
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "exiting ..."
    exit 1
  fi
  echo "================PDI MODULES===================="
  cd ${PSGRS_COMMON_GROUP_DIR}
  PDI_MODULES_DIR=${PSGRS_COMMON_GROUP_DIR}/modules
  echo "PDI_MODULES_DIR: ${PDI_MODULES_DIR}" 
  if [ ! -d "${PDI_MODULES_DIR}" ]; then
    echo "Creating and pointing to default git branch"
    git checkout -b dev
    echo "Creating PDI modules folder ..."
    mkdir ${PDI_MODULES_DIR}
    cd ${PDI_MODULES_DIR}
    echo "Initialising Git Repo ..."
    git init .
    # git hooks wont work here since the directory structure is different
    # echo "Adding Git hooks ..."
    # cp ${PSGRS_SHELL_DIR}/artefacts/git/hooks/* ${PDI_MODULES_DIR}/.git/hooks
    # we have to create a file so that the master branch is created
    echo "creating README file ..."
    touch readme.md
    echo "adding module_1 sample module ..."
    cp -r ${PSGRS_SHELL_DIR}/artefacts/pdi/repo/module_1 .
    git add --all
    git commit -am "initial commit"
  fi
}


function project_code {
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ] || [ -z ${PSGRS_PROJECT_NAME} ] || [ -z ${PSGRS_PDI_STORAGE_TYPE} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "-p <Project Name>"
    echo "-s <PDI Storage Type>"
    echo "exiting ..."
    exit 1
  fi
  echo "================PROJECT CODE===================="
  cd ${PSGRS_PROJECT_GROUP_DIR}
  PROJECT_CODE_DIR=${PSGRS_PROJECT_GROUP_DIR}/${PSGRS_PROJECT_NAME}-code
  echo "PROJECT_CODE_DIR: ${PROJECT_CODE_DIR}"

  if [ ! -d "${PROJECT_CODE_DIR}" ]; then
  
    echo "Creating project code folder ..."
    echo "location: ${PROJECT_CODE_DIR}" 
    mkdir ${PROJECT_CODE_DIR}
    cd ${PROJECT_CODE_DIR}

    echo "Initialising Git Repo ..."
    git init .

    echo "Adding Git hooks ..."
    cp ${PSGRS_SHELL_DIR}/artefacts/git/hooks/* ${PROJECT_CODE_DIR}/.git/hooks
    cp ${PSGRS_SHELL_DIR}/config/settings.sh ${PROJECT_CODE_DIR}/.git/hooks
    perl -0777 \
      -pe "s@\{\{ IS_CONFIG \}\}@N@igs" \
      -i ${PROJECT_CODE_DIR}/.git/hooks/pre-commit 
    if [ ${PSGRS_PDI_STORAGE_TYPE} = "file-based" ]; then
      perl -0777 \
        -pe "s@\{\{ IS_REPO_BASED \}\}@N@igs" \
        -i ${PROJECT_CODE_DIR}/.git/hooks/pre-commit
    else
      perl -0777 \
        -pe "s@\{\{ IS_REPO_BASED \}\}@Y@igs" \
        -i ${PROJECT_CODE_DIR}/.git/hooks/pre-commit
    fi


    echo "Creating and pointing to default git branch"
    git checkout -b dev 
    
    echo "Creating basic folder structure ..."
    mkdir -p pdi/repo/${PSGRS_PROJECT_NAME}
    mkdir -p pdi/sql/ddl
    mkdir -p pentaho-server/repo
    mkdir -p pentaho-server/metadata
    mkdir -p pentaho-server/mondrian
    mkdir -p pentaho-server/prd
    mkdir -p shell-scripts

    # adding file so folders can be committed
    touch pdi/repo/${PSGRS_PROJECT_NAME}/.gitignore
    touch pdi/sql/ddl/.gitignore
    touch pentaho-server/repo/.gitignore 
    touch pentaho-server/metadata/.gitignore 
    touch pentaho-server/mondrian/.gitignore
    touch pentaho-server/prd/.gitignore
    touch shell-scripts/this-folder-contains-non-environment-specific-shell-files.md
    
    cp ${PSGRS_SHELL_DIR}/artefacts/pdi/repo/jb_master.kjb \
       ${PROJECT_CODE_DIR}/pdi/repo/${PSGRS_PROJECT_NAME}
    
    mv ${PROJECT_CODE_DIR}/pdi/repo/${PSGRS_PROJECT_NAME}/jb_master.kjb \
       ${PROJECT_CODE_DIR}/pdi/repo/${PSGRS_PROJECT_NAME}/jb_${PSGRS_PROJECT_NAME}_master.kjb

    echo "Creating basic README file ..."
    echo "Documentation can be found in the dedicated documentation Git repo called ${PSGRS_PROJECT_NAME}-documentation" > readme.md

    if [ ${PSGRS_PDI_STORAGE_TYPE} = "file-repo" ]; then
      echo "Adding kettle db connection files ..."
      cp -r ${PSGRS_SHELL_DIR}/artefacts/pdi/repo/*.kdb pdi/repo

      perl -0777 \
        -pe "s@\{\{ VAR_DB_CONNECTION_NAME \}\}@sample_db_connection@igs" \
        -i ${PROJECT_CODE_DIR}/pdi/repo/db_connection_template.kdb 

      perl -0777 \
        -pe "s@\{\{ PSGRS_PROJECT_NAME \}\}@${PSGRS_PROJECT_NAME}@igs" \
        -i ${PROJECT_CODE_DIR}/pdi/repo/${PSGRS_PROJECT_NAME}/jb_${PSGRS_PROJECT_NAME}_master.kjb 
    fi
    
    if [ ${PSGRS_PDI_STORAGE_TYPE} = "file-based" ]; then
      # nothing to do: shared.xml is part of .kettle, which lives in the config repo
      perl -0777 \
        -pe "s@\{\{ PSGRS_PROJECT_NAME \}\}@@igs" \
        -i ${PROJECT_CODE_DIR}/pdi/repo/${PSGRS_PROJECT_NAME}/jb_${PSGRS_PROJECT_NAME}_master.kjb
    fi

    echo "Adding pdi modules as a git submodule ..."
    
    git submodule add -b master ${PSGRS_MODULES_GIT_REPO_URL} pdi/repo/modules
    git submodule init
    git submodule update

    # echo "Setting branch for submodule ..."
    # cd pdi/repo/modules
    # git checkout master


    # committing new files
    git add --all
    git commit -am "initial commit"

    cd ${PROJECT_CODE_DIR}

    # enable pre-commit hook
    chmod 700 ${PROJECT_CODE_DIR}/.git/hooks/pre-commit
    chmod 700 ${PROJECT_CODE_DIR}/.git/hooks/settings.sh

  fi
}

function project_config {
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ] || [ -z ${PSGRS_PROJECT_NAME} ] || [ -z ${PSGRS_ENV} ] || [ -z ${PSGRS_PDI_STORAGE_TYPE} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "-p <Project Name>"
    echo "-e <Environment>"
    echo "-s <PDI Storage Type>"
    echo "exiting ..."
    exit 1
  fi
  echo "================PROJECT CONFIG=================="
  cd ${PSGRS_PROJECT_GROUP_DIR}
  PROJECT_CONFIG_DIR=${PSGRS_PROJECT_GROUP_DIR}/${PSGRS_PROJECT_NAME}-config-${PSGRS_ENV}
  echo "PROJECT_CONFIG_DIR: ${PROJECT_CONFIG_DIR}"

  if [ ! -d "${PROJECT_CONFIG_DIR}" ]; then 

    echo "Creating project config folder ..."
    echo "location: ${PROJECT_CONFIG_DIR}" 
    mkdir ${PROJECT_CONFIG_DIR}
    cd ${PROJECT_CONFIG_DIR}
  
    echo "Initialising Git Repo ..."
    git init .
  
    echo "Creating and pointing to default git branch"
    git checkout -b master
  
    echo "Adding Git hooks ..."
    cp ${PSGRS_SHELL_DIR}/artefacts/git/hooks/* ${PROJECT_CONFIG_DIR}/.git/hooks
    cp ${PSGRS_SHELL_DIR}/config/settings.sh ${PROJECT_CONFIG_DIR}/.git/hooks
    perl -0777 \
      -pe "s@\{\{ IS_CONFIG \}\}@Y@igs" \
      -i ${PROJECT_CONFIG_DIR}/.git/hooks/pre-commit 
    perl -0777 \
      -pe "s@\{\{ IS_REPO_BASED \}\}@N@igs" \
      -i ${PROJECT_CONFIG_DIR}/.git/hooks/pre-commit
    
    echo "Creating basic folder structure ..."
    
    # mkdir -p pdi/.kettle -> standalone project only
    mkdir -p pdi/metadata
    mkdir -p pdi/properties 
    mkdir -p pdi/schedules
    mkdir -p pdi/shell-scripts 
    mkdir -p pdi/test-data
    mkdir -p pentaho-server/connections

    # adding file so that the folders can be commited
    touch pdi/metadata/.gitignore
    touch pdi/properties/.gitignore
    touch pdi/schedules/.gitignore
    touch pdi/shell-scripts/.gitignore
    touch pdi/test-data/.gitignore
    touch pentaho-server/connections/.gitignore
    
    echo "Adding essential shell files ..."

    cp ${PSGRS_SHELL_DIR}/artefacts/project-config/wrapper.sh \
       ${PROJECT_CONFIG_DIR}/pdi/shell-scripts

    perl -0777 \
      -pe "s@\{\{ PSGRS_PROJECT_NAME \}\}@${PSGRS_PROJECT_NAME}@igs" \
      -i ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/wrapper.sh   


    cp ${PSGRS_SHELL_DIR}/artefacts/project-config/run_jb_name.sh \
       ${PROJECT_CONFIG_DIR}/pdi/shell-scripts
    
    mv ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/run_jb_name.sh \
       ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/run_jb_${PSGRS_PROJECT_NAME}_master.sh

    perl -0777 \
      -pe "s@your_project_name@${PSGRS_PROJECT_NAME}@igs" \
      -i ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/run_jb_${PSGRS_PROJECT_NAME}_master.sh

    perl -0777 \
      -pe "s@jb_name@jb_${PSGRS_PROJECT_NAME}_master@igs" \
      -i ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/run_jb_${PSGRS_PROJECT_NAME}_master.sh

    chmod 700 ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/*.sh
    
    echo "Adding essential properties files ..."

    envsubst \
      < ${PSGRS_SHELL_DIR}/artefacts/project-config/project.properties \
      > ${PROJECT_CONFIG_DIR}/pdi/properties/project.properties
    
    # rename project properies file
    mv ${PROJECT_CONFIG_DIR}/pdi/properties/project.properties \
       ${PROJECT_CONFIG_DIR}/pdi/properties/${PSGRS_PROJECT_NAME}.properties
    
    touch ${PROJECT_CONFIG_DIR}/pdi/properties/jb_${PSGRS_PROJECT_NAME}_master.properties 
    
    # copy deployment scripts across
    # [OPEN]

    # rpm script
    mkdir -p utilities/build-rpm

    cp \
      ${PSGRS_SHELL_DIR}/artefacts/git/package-git-repo.sh \
      ${PROJECT_CONFIG_DIR}/utilities/build-rpm

    cp \
      ${PSGRS_SHELL_DIR}/config/settings.sh \
      ${PROJECT_CONFIG_DIR}/utilities/build-rpm

    envsubst \
      < ${PSGRS_SHELL_DIR}/artefacts/utilities/build-rpm/template.spec \
      > ${PROJECT_CONFIG_DIR}/utilities/build-rpm/template.spec


    echo "Creating basic README file ..."
    echo "Project specific configuration for ${PSGRS_ENV} environment." > ${PROJECT_CONFIG_DIR}/readme.md  

    # commit new files
    git add --all
    git commit -am "initial commit"

    # enable pre-commit hook
    chmod 700 ${PROJECT_CONFIG_DIR}/.git/hooks/pre-commit
    chmod 700 ${PROJECT_CONFIG_DIR}/.git/hooks/settings.sh


  fi
}

function standalone_project_config {
  # This caters for projects that do not need a common project or config
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ] || [ -z ${PSGRS_PROJECT_NAME} ] || [ -z ${PSGRS_ENV} ] || [ -z ${PSGRS_PDI_STORAGE_TYPE} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "-p <Project Name>"
    echo "-e <Environment>"
    echo "-s <PDI Storage Type>"
    echo "exiting ..."
    exit 1
  fi

  project_config

  mkdir -p pdi/.kettle
  cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/.gitignore \
     ${PROJECT_CONFIG_DIR}/pdi/.kettle

  echo "Adding essential shell files ..."

  export PSGRS_KETTLE_HOME=${PROJECT_CONFIG_DIR}/pdi 

  envsubst \
    < ${PSGRS_SHELL_DIR}/artefacts/common-config/set-env-variables.sh \
    > ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh 

  # add_kettle_artefacts
  echo "Adding .kettle files for ${PSGRS_PDI_STORAGE_TYPE} ..."
  cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/kettle.properties \
     ${PROJECT_CONFIG_DIR}/pdi/.kettle

  if [ ${PSGRS_PDI_STORAGE_TYPE} = 'file-repo' ]; then

    export PSGRS_PDI_REPO_NAME=${PSGRS_PROJECT_NAME}
    export PSGRS_PDI_REPO_DESCRIPTION="This is the repo for the ${PSGRS_PROJECT_NAME} project"
    if [ "${PSGRS_PDI_WEBSPOON_SUPPORT}" = "yes" ]; then
      # we mount the project code repo into the Docker container under /root/my-project
      export PSGRS_PDI_REPO_PATH=/root/${PSGRS_DEPLOYMENT_FOLDER_NAME}/${PSGRS_PROJECT_GROUP_NAME}/${PSGRS_PROJECT_NAME}-code/pdi/repo
    else
      export PSGRS_PDI_REPO_PATH=${PSGRS_PROJECT_GROUP_DIR}/${PSGRS_PROJECT_NAME}-code/pdi/repo
    fi

    envsubst \
      < ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/repositories-file.xml \
      > ${PROJECT_CONFIG_DIR}/pdi/.kettle/repositories.xml

  fi

  if [ ${PSGRS_PDI_STORAGE_TYPE} = "file-based" ]; then
    
    cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/shared.xml \
       ${PROJECT_CONFIG_DIR}/pdi/.kettle
  fi

  cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/.spoonrc \
       ${PROJECT_CONFIG_DIR}/pdi/.kettle

  # disable pre-commit hook
  chmod 400 ${PROJECT_CONFIG_DIR}/.git/hooks/pre-commit
  chmod 400 ${PROJECT_CONFIG_DIR}/.git/hooks/settings.sh


  # commit new files
  git add --all
  git commit -am "initial commit"

  # enable pre-commit hook
  chmod 700 ${PROJECT_CONFIG_DIR}/.git/hooks/pre-commit
  chmod 700 ${PROJECT_CONFIG_DIR}/.git/hooks/settings.sh

  echo ""
  echo "==============================="
  echo ""
  echo -e "\e[34m\e[47mIMPORTANT\e[0m"
  echo "Amend the following configuration file:"
  echo "${PROJECT_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh"
  echo ""
  echo "Before using Spoon, source this file:"
  echo "source ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh"
  echo "==============================="
  echo ""

  # echo "Running set-env-variables.sh now so that at least KETTLE_HOME is defined."
  # echo "You can start PDI Spoon now if working on a dev machine."
  echo ""

  source ${PROJECT_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh

}


function common_config {
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ] || [ -z ${PSGRS_ENV} ] || [ -z ${PSGRS_PDI_STORAGE_TYPE} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "-e <Environment>"
    echo "-s <PDI Storage Type>"
    echo "exiting ..."
    exit 1
  fi
  echo "==========COMMON CONFIG=================="
  cd ${PSGRS_COMMON_GROUP_DIR}
  COMMON_CONFIG_DIR=${PSGRS_COMMON_GROUP_DIR}/common-config-${PSGRS_ENV}
  echo "COMMON_CONFIG_DIR: ${COMMON_CONFIG_DIR}"
  if [ ! -d "${COMMON_CONFIG_DIR}" ]; then 

    echo "Creating common config folder ..."
    echo "location: ${COMMON_CONFIG_DIR}" 
    mkdir ${COMMON_CONFIG_DIR}
    cd ${COMMON_CONFIG_DIR}

    echo "Initialising Git Repo ..."
    git init .

    echo "Creating and pointing to default git branch"
    git checkout -b master
    
    echo "Creating basic folder structure ..."
    
    mkdir -p pdi/.kettle 
    cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/.gitignore \
      ${COMMON_CONFIG_DIR}/pdi/.kettle

    mkdir -p pdi/shell-scripts


    echo "Adding Git hooks ..."
    cp ${PSGRS_SHELL_DIR}/artefacts/git/hooks/* ${COMMON_CONFIG_DIR}/.git/hooks
    cp ${PSGRS_SHELL_DIR}/config/settings.sh ${COMMON_CONFIG_DIR}/.git/hooks

    perl -0777 \
      -pe "s@\{\{ IS_CONFIG \}\}@Y@igs" \
      -i ${COMMON_CONFIG_DIR}/.git/hooks/pre-commit 
    perl -0777 \
      -pe "s@\{\{ IS_REPO_BASED \}\}@N@igs" \
      -i ${COMMON_CONFIG_DIR}/.git/hooks/pre-commit

    # add_kettle_artefacts

    echo "Adding .kettle files ..."
    
    cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/kettle.properties \
      pdi/.kettle

    if [ ${PSGRS_PDI_STORAGE_TYPE} = "file-repo" ]; then

      export PSGRS_PDI_REPO_NAME=${PSGRS_PROJECT_NAME}
      export PSGRS_PDI_REPO_DESCRIPTION="This is the repo for the ${PSGRS_PROJECT_NAME} project"
      if [ "${PSGRS_PDI_WEBSPOON_SUPPORT}" = "yes" ]; then
        # we mount the project code repo into the Docker container under /root/my-project
        export PSGRS_PDI_REPO_PATH=/root/${PSGRS_DEPLOYMENT_FOLDER_NAME}/${PSGRS_PROJECT_GROUP_NAME}/${PSGRS_PROJECT_NAME}-code/pdi/repo
      else
        export PSGRS_PDI_REPO_PATH=${PSGRS_PROJECT_GROUP_DIR}/${PSGRS_PROJECT_NAME}-code/pdi/repo
      fi


      envsubst \
        < ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/repositories-file.xml \
        > ${COMMON_CONFIG_DIR}/pdi/.kettle/repositories.xml

    fi
    if [ ${PSGRS_PDI_STORAGE_TYPE} = "file-based" ]; then
      cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/shared.xml \
         pdi/.kettle
    fi
    # ---
    echo "Adding essential shell files ..."

    export PSGRS_KETTLE_HOME=${COMMON_CONFIG_DIR}/pdi 

    envsubst \
      < ${PSGRS_SHELL_DIR}/artefacts/common-config/set-env-variables.sh \
      > ${COMMON_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh 

    cp ${PSGRS_SHELL_DIR}/artefacts/pdi/.kettle/.spoonrc \
       ${COMMON_CONFIG_DIR}/pdi/.kettle

    # commit new files
    git add --all
    git commit -am "initial commit"

    # enable pre-commit hook
    chmod 700 ${COMMON_CONFIG_DIR}/.git/hooks/pre-commit
    chmod 700 ${COMMON_CONFIG_DIR}/.git/hooks/settings.sh


    echo "Creating basic README file ..."
    echo "Common configuration for ${PSGRS_ENV} environment." > ${COMMON_CONFIG_DIR}/readme.md

    echo ""
    echo "==============================="
    echo ""
    echo -e "\e[34m\e[47mIMPORTANT\e[0m"
    echo "Amend the following configuration file:"
    echo "${COMMON_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh"
    echo ""
    echo ""
    echo "Before using Spoon, source this file:"
    echo "source ${COMMON_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh"
    echo "==============================="
    echo ""

    # echo "Running set-env-variables.sh now so that at least KETTLE_HOME is defined."
    # echo "You can start PDI Spoon now if working on a dev machine."
    echo ""

    source ${COMMON_CONFIG_DIR}/pdi/shell-scripts/set-env-variables.sh
  fi
}


function project_docu {
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ] || [ -z ${PSGRS_PROJECT_NAME} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "-p <Project Name>"
    echo "exiting ..."
    exit 1
  fi
  echo "===========PROJECT DOCUMENTATION=================="
  cd ${PSGRS_PROJECT_GROUP_DIR}
  PROJECT_DOCU_DIR=${PSGRS_PROJECT_GROUP_DIR}/${PSGRS_PROJECT_NAME}-documentation
  echo "PROJECT_DOCU_DIR: ${PROJECT_DOCU_DIR}"
  if [ ! -d "${PROJECT_DOCU_DIR}" ]; then 

    echo "Creating project documentation folder ..."
    echo "location: ${PROJECT_DOCU_DIR}"
    
    mkdir ${PROJECT_DOCU_DIR}
    cd ${PROJECT_DOCU_DIR}

    echo "Initialising Git Repo ..."
    git init .
    
    echo "Creating and pointing to default git branch"
    git checkout -b master

    echo "Creating basic README file ..."
    echo "# Documentation for ${PSGRS_PROJECT_NAME}" > ${PROJECT_DOCU_DIR}/readme.md

    # commit new files
    git add --all
    git commit -am "initial commit"

  fi
}

function common_docu {
  # check if required parameter values are available
  if [ -z ${PSGRS_ACTION} ]; then
    echo "Not all required arguments were supplied. Required:"
    echo "-a <PSGRS_ACTION>"
    echo "exiting ..."
    exit 1
  fi
  echo "===========COMMON DOCUMENTATION=================="
  cd ${PSGRS_COMMON_GROUP_DIR}
  COMMON_DOCU_DIR=${PSGRS_COMMON_GROUP_DIR}/common-documentation
  echo "COMMON_DOCU_DIR: ${COMMON_DOCU_DIR}"
  if [ ! -d "${COMMON_DOCU_DIR}" ]; then 

    echo "Creating project documentation folder ..."
    echo "location: ${COMMON_DOCU_DIR}"

    mkdir ${COMMON_DOCU_DIR}
    cd ${COMMON_DOCU_DIR}

    echo "Initialising Git Repo ..."
    git init .
    
    echo "Creating and pointing to default git branch"
    git checkout -b master

    echo "Creating basic README file ..."
    echo "# Common Documentation" > ${COMMON_DOCU_DIR}/readme.md

    # commit new files
    git add --all
    git commit -am "initial commit"

  fi
}


# full setup with common config
if [ ${PSGRS_ACTION} = "1" ]; then 
  project_config
  project_code
  project_docu
  common_docu
  common_config

  # copy utility scripts
  cd ${PSGRS_DEPLOYMENT_DIR}
  cp ${PSGRS_SHELL_DIR}/artefacts/git/update-all-git-repos.sh .

  if [ "${PSGRS_PDI_WEBSPOON_SUPPORT}" = "yes" ]; then
cat > ${PSGRS_DEPLOYMENT_DIR}/start-webspoon.sh <<EOL
sudo docker run -it --rm \
-e JAVA_OPTS="-Xms1024m -Xmx2048m" \
-e KETTLE_HOME="/root/${PSGRS_DEPLOYMENT_FOLDER_NAME}/${PSGRS_COMMON_GROUP_NAME}/common-config-${PSGRS_ENV}/pdi/" \
-p 8080:8080 \
-v ${PSGRS_DEPLOYMENT_DIR}:/root/${PSGRS_DEPLOYMENT_FOLDER_NAME}/:z \
hiromuhota/webspoon:latest-full
echo ""
echo "WebSpoon UI available on http://localhost:8080/spoon/spoon"
echo "Note: Any shell scripts have to be executed from within the container!"
echo "The config is set up to only work within the container!"
EOL
  fi

  chmod 700 ${PSGRS_DEPLOYMENT_DIR}/*.sh

fi

# full setup without common config
if [ ${PSGRS_ACTION} = "2" ]; then 
  project_code
  project_docu
  standalone_project_config

  # copy utility scripts
  cd ${PSGRS_DEPLOYMENT_DIR}
  cp ${PSGRS_SHELL_DIR}/artefacts/git/update-all-git-repos.sh .

  if [ "${PSGRS_PDI_WEBSPOON_SUPPORT}" = "yes" ]; then
cat > ${PSGRS_DEPLOYMENT_DIR}/start-webspoon.sh <<EOL
sudo docker run -it --rm \
-e JAVA_OPTS="-Xms1024m -Xmx2048m" \
-e KETTLE_HOME="/root/${PSGRS_DEPLOYMENT_FOLDER_NAME}/${PSGRS_PROJECT_GROUP_NAME}/${PSGRS_PROJECT_NAME}-config-${PSGRS_ENV}/pdi/" \
-p 8080:8080 \
-v ${PSGRS_PROJECT_GROUP_DIR}:/root/${PSGRS_DEPLOYMENT_FOLDER_NAME}/:z \
hiromuhota/webspoon:latest-full
echo ""
echo "WebSpoon UI available on http://localhost:8080/spoon/spoon"
echo "Note: Any shell scripts have to be executed from within the container!"
echo "The config is set up to only work within the container!"
EOL
  fi
  chmod 700 ${PSGRS_DEPLOYMENT_DIR}/*.sh

fi

if [ ${PSGRS_ACTION} = "pdi_module" ]; then 
  pdi_module
fi

if [ ${PSGRS_ACTION} = "project_code" ]; then
  project_code
fi

if [ ${PSGRS_ACTION} = "project_config" ]; then
  project_config
fi

if [ ${PSGRS_ACTION} = "standalone_project_config" ]; then
  standalone_project_config
fi

if [ ${PSGRS_ACTION} = "common_config" ]; then
  common_config
fi

if [ ${PSGRS_ACTION} = "project_docu" ]; then
  project_docu
fi

if [ ${PSGRS_ACTION} = "common_docu" ]; then
  common_docu
fi
