#!/usr/bin/env bash
#
# Author: GauchoCode - A Software Development Agency - https://gauchocode.com
# Version: 3.3.5
################################################################################
#
# Storage Controller: Controller to upload and download backups.
#
################################################################################

################################################################################
#
# Important: Backup/Restore utils selection with borg.
#
#   Backup Uploader:
#       Simple way to upload backup file to this cloud service.
#
################################################################################

################################################
# umount storage box
#
# Arguments:
#   ${1} = {directory}
#
# Outputs:
#   None
################################################


function umount_storage_box() {

  local directory="${1}"

  is_mounted=$(mount -v | grep "storage-box" > /dev/null; echo "$?")

  if [[ ${is_mounted} -eq 0 ]]; then
        log_subsection "Desmontando storage-box"
        umount ${directory}
  fi

}

#################################################
# mount storage box
#
# Arguments:
#   ${1} = {directory}
#
# Outputs:
#   None
################################################

function mount_storage_box() {

  local directory="${1}"

  is_mounted=$(mount -v | grep "storage-box" > /dev/null; echo "$?")

  if [[ ${is_mounted} -eq 1 ]]; then
      log_subsection "Montando storage-box"
      sshfs -o default_permissions -p ${BACKUP_BORG_PORT} ${BACKUP_BORG_USER}@${BACKUP_BORG_SERVER}:/home/applications ${directory}
  fi

}


#################################################
# restore backup with borg
#
# Arguments:
#   ${1} = {server_hostname}
#
# Outputs:
#   Return 0 if ok, 1 on error. 
################################################

function restore_backup_with_borg() {
    
    local storage_box_directory="/mnt/storage-box"

    # Create storage box directory if not exists where it will be mounted
    [[ ! -d ${storage_box_directory} ]] && mkdir ${storage_box_directory}

    log_section "Restore Backup"

    # umount storage box
    umount_storage_box ${storage_box_directory} && sleep 1

    # mount storage box
    mount_storage_box ${storage_box_directory} && sleep 1

    local storage_box_directory=${storage_box_directory}
    local remote_server_list=$(find "${storage_box_directory}/${BACKUP_BORG_GROUP}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

    # Menu
    local chosen_server=$(whiptail --title "BACKUP SELECTION" --menu "Choose a server to work with" 20 78 10 $(for x in ${remote_server_list}; do echo "${x} [D]"; done) --default-item "${SERVER_NAME}" 3>&1 1>&2 2>&3)

    if [[ ${chosen_server} != ""  ]]; then
        log_subsection "Restore Project Backup"
        restore_project_with_borg "${chosen_server}"
    else
        display --indent 6 --text "- Selecting Project Backup" --result "SKIPPED" --color YELLOW
        return 1
    fi

    umount_storage_box ${storage_box_directory}

}

function generate_tar_and_decompress() {
    
    local chosen_archive="${1}"
    local project_domain="${2}"
    local project_install_type="${3}"
    local project_backup_file=${chosen_archive}.tar.bz2
    local destination_dir="${PROJECTS_PATH}/${project_domain}"
    
    borg export-tar --tar-filter='auto' --progress ssh://${BACKUP_BORG_USER}@${BACKUP_BORG_SERVER}:${BACKUP_BORG_PORT}/./applications/${BACKUP_BORG_GROUP}/${server_hostname}/projects-online/site/${chosen_domain}::${chosen_archive} ${BROLIT_MAIN_DIR}/tmp/${project_backup_file}

    exitstatus=$?

    if [[ exitstatus -eq 0 ]]; then
        display --indent 6 --text "- Exporting compressed file from storage box" --result "DONE" --color GREEN
        log_event "info" "${project_backup_file} downloaded" "false"
    else
        echo "Error al exportar el archivo ${project_backup_file}"
        exit 1
    fi

    #log_event "info" "Extracting compressed file: ${project_backup_file}" "false"
    #display --indent 6 --text "- Extracting compressed file"

    if [ -f "${BROLIT_MAIN_DIR}/tmp/${project_backup_file}" ]; then

        # If project directory exists, make a backup of it
        if [[ -d "${destination_dir}" ]]; then

            whiptail --title "Warning" --yesno "The project directory already exist. Do you want to continue? A backup of current directory will be stored on BROLIT tmp folder." 10 60 3>&1 1>&2 2>&3

            exitstatus=$?
            if [[ ${exitstatus} -eq 0 ]]; then

            # If project_install_type == docker, stop and remove containers
            if [[ ${project_install_type} == "docker"* ]]; then

                # Stop containers
                docker_compose_stop "${destination_dir}/docker-compose.yml"

                # Remove containers
                docker_compose_rm "${destination_dir}/docker-compose.yml"

            fi

            # Backup old project
            _create_tmp_copy "${destination_dir}" "move"
            [[ $? -eq 1 ]] && return 1

            else

            # Log
            log_event "info" "The project directory already exist. User skipped operation." "false"
            display --indent 6 --text "- Restore files" --result "SKIPPED" --color YELLOW

            return 1

            fi

        fi

        # Extract project
        pv --width 70 "${BROLIT_MAIN_DIR}/tmp/${project_backup_file}" | tar xpj -C / var/www

        # if extracted ok then
        if [[ $? -eq 0 ]]; then

            clear_previous_lines "2"

            log_event "info" "${file_path} extracted ok!" "false"
            display --indent 6 --text "- Extracting compressed file" --result "DONE" --color GREEN

            return 0

        else

            clear_previous_lines "2"

            log_event "error" "Error extracting ${file_path}" "false"
            display --indent 6 --text "- Extracting compressed file" --result "FAIL" --color RED

            return 1

        fi       

        sleep 1

        rm -rf ${BROLIT_MAIN_DIR}/tmp/${project_backup_file}
        [[ $? -eq 0 ]] && echo "Eliminando archivos temporales"
    else

        echo "Error al exportar el archivo ${project_backup_file}"
        exit 1

    fi

}


#################################################
# restore project with borg
#
# Arguments:
#   ${1} = {server_hostname}
#
# Outputs:
#   None
################################################

function restore_project_with_borg() {

    local server_hostname="${1}"
    local storage_box_directory="/mnt/storage-box"

    # Create storage-box directory if not exists
    remote_domain_list=$(find "${storage_box_directory}/${BACKUP_BORG_GROUP}/${server_hostname}" -maxdepth 3 -mindepth 3 -type d -exec basename {} \; | sort)

    chosen_domain="$(whiptail --title "BACKUP SELECTION" --menu "Choose a domain to work with" 20 78 10 $(for x in ${remote_domain_list}; do echo "${x} [D]"; done) --default-item "${SERVER_NAME}" 3>&1 1>&2 2>&3)"

    local project_name="$(project_get_name_from_domain "${chosen_domain}")"
    local destination_dir="${PROJECTS_PATH}/${chosen_domain}"

    if [[ -d $destination_dir ]]; then
        local project_install_type="$(project_get_install_type "${destination_dir}")"
    else
        log_event "info" "${project_domain} not found - Downloading project" "false"
    fi

    if [[ ${chosen_domain} != "" ]]; then

        arhives="$(borg list --format '{archive}{NL}' ssh://${BACKUP_BORG_USER}@${BACKUP_BORG_SERVER}:${BACKUP_BORG_PORT}/./applications/${BACKUP_BORG_GROUP}/${server_hostname}/projects-online/site/${chosen_domain} | sort -r)"

        chosen_archive="$(whiptail --title "BACKUP SELECTION" --menu "Choose an archive to work with" 20 78 10 $(for x in ${arhives}; do echo "${x} [D]"; done) --default-item "${SERVER_NAME}" 3>&1 1>&2 2>&3)"

        if [[ ${chosen_archive} != "" ]]; then
            display --indent 6 --text "- Selecting Project Backup" --result "DONE" --color GREEN
            display --indent 8 --text "${chosen_archive}.tar.bz2" --tcolor YELLOW
            generate_tar_and_decompress "${chosen_archive}" "${chosen_domain}" "${project_install_type}"

            # If project_install_type == docker, build containers
            if [[ ${project_install_type} == "docker"* ]]; then
                log_subsection "Restore Files Backup"
                docker_setup_configuration "${project_name}" "${destination_dir}" "${chosen_domain}"
                docker_compose_build "${destination_dir}/docker-compose.yml"
            fi                
        else
            display --indent 6 --text "- Selecting Project Backup" --result "SKIPPED" --color YELLOW
            return 1
        fi

    fi 

}