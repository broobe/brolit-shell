#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2.3
################################################################################
#
# Docker Helper: Perform docker actions.
#
################################################################################

################################################################################
# Get docker version.
#
# Arguments:
#   none
#
# Outputs:
#   ${docker_version} if ok, 1 on error.
################################################################################

function docker_version() {

    local docker_version
    local docker

    docker="$(package_is_installed "docker")"
    if [[ -n ${docker} ]]; then

        docker_version="$(docker version --format '{{.Server.Version}}')"

        echo "${docker_version}"

        return 0
    else

        return 1

    fi

}

################################################################################
# Get docker-compose version.
#
# Arguments:
#   none
#
# Outputs:
#   ${docker_compose_version} if ok, 1 on error.
################################################################################

function docker_compose_version() {

    local docker_compose_version
    local docker_compose

    docker_compose="$(package_is_installed "docker-compose")"
    if [[ -n ${docker_compose} ]]; then

        docker_compose_version="$(docker-compose --version | awk '{print $3}' | cut -d ',' -f1)"

        echo "${docker_compose_version}"

        return 0
    else

        return 1

    fi

}

################################################################################
# List docker containers.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_list_containers() {

    local docker_containers

    # List docker containers.
    docker_containers="$(docker ps -a --format '{{.Names}}')"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        echo "${docker_containers}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Stop docker container.
#
# Arguments:
#   $1 = ${container_to_stop}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_stop_container() {

    local container_to_stop="${1}"

    local docker_stop_container

    # Stop docker container.
    docker_stop_container="$(docker stop "${container_to_stop}")"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        echo "${docker_stop_container}"

        return 0

    else

        return 1

    fi

}

################################################################################
# List docker images.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_list_images() {

    local docker_images

    # Docker list images
    docker_images="$(docker images --format '{{.Repository}}:{{.Tag}}')"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        echo "${docker_images}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Get container id
#
# Arguments:
#   $1 = ${image_name}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_get_container_id() {

    local image_name="${1}"

    local container_id

    container_id="$(docker ps | grep "${image_name}" | awk '{print $1;}')"

    if [[ -n ${container_id} ]]; then

        echo "${container_id}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Docker delete image.
#
# Arguments:
#   $1 = ${image_to_delete}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_delete_image() {

    local image_to_delete="${1}"

    local docker_delete_image

    # Docker delete image
    docker_delete_image="$(docker rmi "${image_to_delete}")"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        echo "${docker_delete_image}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Docker system prune.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_system_prune() {

    echo "Docker system prune: $(docker system prune)"

}

################################################################################
# Docker WordPress install.
#
# Arguments:
#   $1 = ${project_path}
#   $2 = ${project_domain}
#   $3 = ${project_name}
#   $4 = ${project_stage}
#   $5 = ${project_root_domain}         # Optional
#   $6 = ${docker_compose_template}     # Optional
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_wordpress_install() {

    local project_path="${1}"
    local project_domain="${2}"
    local project_name="${3}"
    local project_stage="${4}"
    local project_root_domain="${5}"
    local docker_wp_port="${6}"
    local docker_compose_template="${7}"

    local env_file

    log_subsection "WordPress Install (Docker)"

    # First checks
    ## Directory
    if [[ -d ${project_path} ]]; then
        log_event "error" "Project directory already exists." "false"
        return 1
    fi
    ## Local Port
    network_port_is_use "${docker_wp_port}"
    if [[ ${exitstatus} -eq 0 ]]; then
        log_event "error" "Can't use port ${docker_wp_port}. Please choose another one." "false"
        return 1
    fi

    # Create directory structure
    mkdir -p "${project_path}"
    log_event "info" "Working directory: ${project_path}" "false"

    # Copy docker-compose template files
    cp "${BROLIT_MAIN_DIR}/config/docker-compose/wordpress/.env" "${project_path}"
    cp "${BROLIT_MAIN_DIR}/config/docker-compose/wordpress/docker-compose.yml" "${project_path}"

    # Replace variables on .env file
    env_file="${project_path}/.env"
    compose_file="${project_path}/docker-compose.yml"

    # Setting WP_PORT
    log_event "debug" "Setting WP_PORT=${docker_wp_port}" "false"
    sed -ie "s|^WP_PORT=.*$|WP_PORT=${docker_wp_port}|g" "${env_file}"

    # Setting PROJECT_NAME
    log_event "debug" "Setting PROJECT_NAME=${project_name}" "false"
    sed -ie "s|^PROJECT_NAME=.*$|PROJECT_NAME=${project_name}|g" "${env_file}"

    # Setting PROJECT_DOMAIN
    log_event "debug" "Setting PROJECT_DOMAIN=${project_domain}" "false"
    sed -ie "s|^PROJECT_DOMAIN=.*$|PROJECT_DOMAIN=${project_domain}|g" "${env_file}"

    # Setting PHPMYADMIN_DOMAIN
    log_event "debug" "Setting PHPMYADMIN_DOMAIN=db.${project_domain}" "false"
    sed -ie "s|^PHPMYADMIN_DOMAIN=.*$|PHPMYADMIN_DOMAIN=db.${project_domain}|g" "${env_file}"

    # TODO: replace
    #### MYSQL_DATABASE=db_name
    #### MYSQL_USER=db_user
    #### MYSQL_PASSWORD=db_user_pass
    #### MYSQL_ROOT_PASSWORD='root_pass'
    #### MYSQL_DATA_DIR=./mysql_data

    # Run docker-compose commands
    docker-compose -f "${compose_file}" pull
    docker-compose -f "${compose_file}" up -d

    # TODO:
    ## 1- Create new nginx with proxy config.
    ## 2- Update cloudflare DNS entries.
    ## 3- Run certbot.
    ## 4- Make changes on .htaccess
    ### Add this lines:
    ##### php_value upload_max_filesize 600M
    ##### php_value post_max_size 600M
    ## 5- Make changes on wp-config.php
    ### At this lines at the top of the file (${DOMAIN} should be replaced):
    ##### define('FORCE_SSL_ADMIN', true);
    ##### define('FORCE_SSL_LOGIN', true);
    ##### if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https'){ $_SERVER['HTTPS']='on'; }
    ##### define('WP_HOME','https://${DOMAIN}/');
    ##### define('WP_SITEURL','https://${DOMAIN}/');
    ## 5- Create brolit project config.

}

################################################################################
# Docker MySQL database import
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_mysql_database_import() {

    local container_name="${1}"
    local mysql_user="${2}"
    local mysql_user_passw="${3}"
    local mysql_database="${4}"
    local dump_file="${5}"

    # TODO:
    # 1- List container names
    # 2- Select container name to work with

    # Docker run
    # Example: docker exec -i db mysql -uroot -pexample wordpress < dump.sql
    log_event "debug" "Running: docker exec -i \"${container_name}\" mysql -u\"${mysql_user}\" -p\"${mysql_user_passw}\" ${mysql_database} < ${dump_file}" "false"
    docker exec -i "${container_name}" mysql -u"${mysql_user}" -p"${mysql_user_passw}" "${mysql_database}" <"${dump_file}"

    # Docker logs
    #docker logs wordpress

}

################################################################################
# Docker MySQL database backup
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_mysql_database_export() {

    local container_name="${1}"
    local mysql_user="${2}"
    local mysql_user_passw="${3}"
    local mysql_database="${4}"
    local dump_file="${5}"

    # Docker run
    # Example: docker exec -i db mysqldump -uroot -pexample wordpress > dump.sql
    log_event "debug" "Running: docker exec -i \"${container_name}\" mysql -u\"${mysql_user}\" -p\"${mysql_user_passw}\" ${mysql_database} > ${dump_file}" "false"

    # Docker command
    docker exec -i "${container_name}" mysqldump -u"${mysql_user}" -p"${mysql_user_passw}" "${mysql_database}" >"${dump_file}"

    # Docker logs
    #docker logs wordpress

}

################################################################################
# Docker project files import on volume
#
# Arguments:
#   $1 = ${project_files}
#   $2 = ${project_path}
#   $3 = ${project_type}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_project_files_import() {

    local project_backup_file="${1}"
    local project_path="${2}"
    local project_type="${3}"

    local project_backup_path
    local project_volume_path
    local delimiter
    local key
    local rand

    rand="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 3 | head -n 1)"
    project_backup_path="${BROLIT_MAIN_DIR}/tmp/${rand}"
    mkdir -p "${project_backup_path}"

    decompress "${project_backup_file}" "${project_backup_path}" "lbzip2"

    # Get inner directory (should be only one)
    inner_dir="$(get_all_directories "${project_backup_path}")"

    # Read ${project_path}/.env on root?
    if [[ -f "${project_path}/.env" ]]; then

        delimiter="="
        key="WWW_DATA_DIR"
        project_volume_path=$(cat "${project_path}/.env" | grep "^${key} ${delimiter}" | cut -f2- -d"${delimiter}")

        if [[ -n ${project_volume_path} ]]; then

            # TODO: check if volume is created? check if container is running?
            copy_files "${project_backup_path}/${inner_dir}" "${project_volume_path}"

        fi

    fi

}

### NEW NEW NEW NEW NEW NEW NEW

################################################################################
# Docker create new project install
# Arguments:
#   $1 = ${dir_path}
#   $2 = ${project_type}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_project_install() {

    local dir_path="${1}"
    local project_type="${2}"

    local project_path
    local port_available

    # PUT ON A NEW FUNCTION?

    # Project Type
    #if [[ -z ${project_type} ]]; then
    #    project_type="$(project_ask_type "")"
    #    [[ $? -eq 1 ]] && return 1
    #fi

    log_section "Project Installer (${project_type} on docker)"

    # Project Port (docker internal)
    ## Will find the next port available from 81 to 200
    port_available="$(network_next_available_port "81" "200")"

    # Project Domain
    if [[ -z ${project_domain} ]]; then
        project_domain="$(project_ask_domain "")"
        [[ $? -eq 1 ]] && return 1
    fi

    # If ${dir_path} is empty, use default project path
    [[ -z ${dir_path} ]] && dir_path="${PROJECTS_PATH}"

    # Project Path
    project_path="${dir_path}/${project_domain}"

    # Project root domain
    project_root_domain="$(domain_get_root "${project_domain}")"

    # TODO: check when add www.DOMAIN.com and then select other stage != prod
    if [[ -z ${project_stage} ]]; then

        suggested_state="$(domain_get_subdomain_part "${project_domain}")"

        # Project stage
        project_stage="$(project_ask_stage "${suggested_state}")"
        exitstatus=$?
        if [[ ${exitstatus} -eq 1 ]]; then
            # Log
            log_event "info" "Operation cancelled!" "false"
            display --indent 2 --text "- Asking project stage" --result SKIPPED --color YELLOW
            return 1
        fi

    fi

    if [[ -z ${project_name} ]]; then

        possible_project_name="$(project_get_name_from_domain "${project_domain}")"

        # Project Name
        project_name="$(project_ask_name "${possible_project_name}")"
        exitstatus=$?
        if [[ ${exitstatus} -eq 1 ]]; then
            # Log
            log_event "info" "Operation cancelled!" "false"
            display --indent 2 --text "- Asking project name" --result SKIPPED --color YELLOW
            return 1
        fi

    fi

    [[ ${project_domain} == "${project_root_domain}" ]] && project_domain="www.${project_domain}" && project_secondary_subdomain="${project_root_domain}"

    case ${project_type} in

    wordpress)

        # Create project directory
        mkdir -p "${project_path}"

        # Copy docker-compose files
        copy_files "${BROLIT_MAIN_DIR}/config/docker-compose/wordpress/production-stack-proxy/" "${project_path}"

        # Replace .env vars
        local wp_port="${port_available}"
        local project_database="${project_name}_${project_stage}"
        local project_database_user="${project_name}_user"
        local project_database_user_passw=$(openssl rand -hex 5)
        local project_database_root_passw=$(openssl rand -hex 5)

        ## PROJECT
        sed -ie "s|^PROJECT_NAME=.*$|PROJECT_NAME=${project_name}|g" "${project_path}/.env"
        sed -ie "s|^PROJECT_DOMAIN=.*$|PROJECT_DOMAIN=${project_domain}|g" "${project_path}/.env"

        ## WP
        sed -ie "s|^WP_PORT=.*$|WP_PORT=${wp_port}|g" "${project_path}/.env"

        ##  MYSQL
        sed -ie "s|^MYSQL_DATABASE=.*$|MYSQL_DATABASE=${project_database}|g" "${project_path}/.env"
        sed -ie "s|^MYSQL_USER=.*$|MYSQL_USER=${project_database_user}|g" "${project_path}/.env"
        sed -ie "s|^MYSQL_PASSWORD=.*$|MYSQL_PASSWORD=${project_database_user_passw}|g" "${project_path}/.env"
        sed -ie "s|^MYSQL_ROOT_PASSWORD=.*$|MYSQL_ROOT_PASSWORD=${project_database_root_passw}|g" "${project_path}/.env"

        # Remove tmp file
        rm "${project_path}/.enve"

        local compose_file="${project_path}/docker-compose.yml"

        # Execute docker-compose commands
        docker-compose -f "${compose_file}" pull --quiet
        docker-compose -f "${compose_file}" up --detach # Not quiet option. FRQ: https://github.com/docker/compose/issues/6026

        # Check exitcode
        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then

            # Log
            wait 2
            clear_previous_lines "6"
            log_event "info" "Downloading docker images." "false"
            log_event "info" "Building docker images." "false"
            display --indent 6 --text "- Downloading docker images" --result "DONE" --color GREEN
            display --indent 6 --text "- Building docker images" --result "DONE" --color GREEN

            # Add .htaccess
            echo "# PHP Values" >"${project_path}/wordpress/.htaccess"
            echo "php_value upload_max_filesize 500M" >>"${project_path}/wordpress/.htaccess"
            echo "php_value post_max_size 500M" >>"${project_path}/wordpress/.htaccess"

            # Log
            log_event "info" "Creating .htaccess with needed php parameters." "false"
            display --indent 6 --text "- Creating .htaccess on project" --result "DONE" --color GREEN

            # Edit wp-config.php
            echo "define('FORCE_SSL_ADMIN', true);" >>"${project_path}/wordpress/wp-config.php"
            echo "if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false){" >>"${project_path}/wordpress/wp-config.php"
            echo "  \$_SERVER['HTTPS'] = 'on';" >>"${project_path}/wordpress/wp-config.php"
            echo "  \$_SERVER['SERVER_PORT'] = 443;" >>"${project_path}/wordpress/wp-config.php"
            echo "}" >>"${project_path}/wordpress/wp-config.php"
            echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_HOST'])) {" >>"${project_path}/wordpress/wp-config.php"
            echo "  \$_SERVER['HTTP_HOST'] = \$_SERVER['HTTP_X_FORWARDED_HOST'];" >>"${project_path}/wordpress/wp-config.php"
            echo "}" >>"${project_path}/wordpress/wp-config.php"
            echo "define('WP_HOME','https://${project_domain}/');" >>"${project_path}/wordpress/wp-config.php"
            echo "define('WP_SITEURL','https://${project_domain}/');" >>"${project_path}/wordpress/wp-config.php"

            # Log
            log_event "info" "Making changes on wp-config.php to work with nginx proxy on host." "false"
            display --indent 6 --text "- Making changes on wp-config.php" --result "DONE" --color GREEN

            # Execute function
            #wordpress_project_installer "${project_path}" "${project_domain}" "${project_name}" "${project_stage}" "${project_root_domain}" "${project_install_mode}"
        fi

        ;;

        #    laravel)
        #        # Execute function
        #        # laravel_project_installer "${project_path}" "${project_domain}" "${project_name}" "${project_stage}" "${project_root_domain}"
        #        # log_event "warning" "Laravel installer should be implemented soon, trying to install like pure php project ..."
        #        php_project_installer "${project_path}" "${project_domain}" "${project_name}" "${project_stage}" "${project_root_domain}"
        #
        #        ;;
        #
        #    php)
        #
        #        php_project_installer "${project_path}" "${project_domain}" "${project_name}" "${project_stage}" "${project_root_domain}"
        #
        #        ;;
        #
    *)
        log_event "error" "Project type '${project_type}' unkwnown, aborting ..." "false"
        return 1
        ;;

    esac

    ### NEW ###

    # Project domain configuration (webserver+certbot+DNS)
    https_enable="$(project_update_domain_config "${project_domain}" "proxy" "${port_available}")"

    # Startup Script for WordPress installation
    #if [[ ${https_enable} == "true" ]]; then
    #    project_site_url="https://${project_domain}"
    #else
    #    project_site_url="http://${project_domain}"
    #fi

    #[[ ${EXEC_TYPE} == "default" && ${project_type} == "wordpress" ]] && wpcli_run_startup_script "${project_path}" "${project_site_url}"

    # Post-restore/install tasks
    #project_post_install_tasks "${project_path}" "${project_type}" "${project_name}" "${project_stage}" "${database_user_passw}" "" ""

    # TODO: refactor this
    # Cert config files
    cert_path=""
    if [[ -d "/etc/letsencrypt/live/${project_domain}" ]]; then
        cert_path="/etc/letsencrypt/live/${project_domain}"
    else
        if [[ -d "/etc/letsencrypt/live/www.${project_domain}" ]]; then
            cert_path="/etc/letsencrypt/live/www.${project_domain}"
        fi
    fi

    # Create project config file
    # Arguments:
    #  $1 = ${project_path}
    #  $2 = ${project_name}
    #  $3 = ${project_stage}
    #  $4 = ${project_type}
    #  $5 = ${project_db_status}
    #  $6 = ${project_db_engine}
    #  $7 = ${project_db_name}
    #  $8 = ${project_db_host}
    #  $9 = ${project_db_user}
    #  $10 = ${project_db_pass}
    #  $11 = ${project_prymary_subdomain}
    #  $12 = ${project_secondary_subdomains}
    #  $13 = ${project_override_nginx_conf}
    #  $14 = ${project_use_http2}
    #  $15 = ${project_certbot_mode}
    project_update_brolit_config "${project_path}" "${project_name}" "${project_stage}" "${project_type} " "enabled" "mysql" "${database_name}" "localhost" "${database_user}" "${database_user_passw}" "${project_domain}" "${project_secondary_subdomain}" "/etc/nginx/sites-available/${project_domain}" "" "${cert_path}"

    # Log
    log_event "info" "New ${project_type} project installation for '${project_domain}' finished ok." "false"
    display --indent 6 --text "- ${project_type} project installation" --result "DONE" --color GREEN
    display --indent 8 --text "for domain ${project_domain}"

    # Send notification
    send_notification "✅ ${SERVER_NAME}" "New ${project_type} project (docker) installation for '${project_domain}' finished ok!" ""

}
