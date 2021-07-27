#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.0.50
#############################################################################

function test_wpcli_helper_funtions() {

    local project_name
    local project_state
    local project_domain
    local project_path

    project_name="domain"
    project_state="test"
    project_domain="test.domain.com"
    project_path="${SITES}/${project_domain}"

    # Create mock project
    db_project_name=$(mysql_name_sanitize "${project_name}")
    database_name="${db_project_name}_${project_state}"
    database_user="${db_project_name}_user"
    database_user_passw="$(openssl rand -hex 12)"

    mysql_database_create "${database_name}"
    mysql_user_create "${database_user}" "${database_user_passw}"
    mysql_user_grant_privileges "${database_user}" "${database_name}"

    # Download WordPress
    wpcli_core_download "${project_path}"

    # Create wp-config.php
    wpcli_create_config "${project_path}" "${database_name}" "${database_user}" "${database_user_passw}" "es_ES"

    # Tests

    test_wpcli_option_get_home "${project_path}"

    #test_wpcli_get_wpcore_version "${SITES}/${project_domain}"

    #test_wpcli_get_db_prefix "${SITES}/${project_domain}"

    #test_wpcli_change_tables_prefix "${SITES}/${project_domain}"

    #test_wpcli_get_db_prefix "${SITES}/${project_domain}"

    # Destroy mock project
    #rm -R "${SITES}/${project_domain}"
    #mysql_database_drop "${database_name}"
    #mysql_user_delete "${database_user}" "localhost"

}
function test_wpcli_option_get_home() {

    local project_path=$1

    log_subsection "Test: test_wpcli_option_get_home"

    result="$(wpcli_option_get_home "${project_path}")"
    if [[ ${result} = "http://test.domain.com" ]]; then
        display --indent 6 --text "- wpcli_option_get_home" --result "PASS" --color WHITE
        display --indent 6 --text "result: ${result}" --tcolor GREEN
    else
        display --indent 6 --text "- wpcli_option_get_home" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

}

function test_wordpress_helper_funtions() {

    local project_domain

    log_subsection "Test: test_wordpress_helper_funtions"

    project_domain="test.domain.com"

    # Create mock project
    wpcli_core_download "${SFOLDER}/tmp/${project_domain}"

    # Tests
    test_wp_config_path "${SFOLDER}/tmp/${project_domain}"
    test_is_wp_project "${SFOLDER}/tmp/${project_domain}"

    # Deleting temp files
    #rm -R "${SITES}/${project_domain}"

}

function test_wp_config_path() {

    log_subsection "Test: test_wp_config_path"

    result="$(wp_config_path "${project_path}")"
    if [[ ${result} != "" ]]; then
        display --indent 6 --text "- wp_config_path result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- wp_config_path" --result "FAIL" --color RED
        #display --indent 6 --text "result: ${result}" --tcolor RED
    fi

}

function test_is_wp_project() {

    log_subsection "Test: test_is_wp_project"

    result="$(is_wp_project "${project_path}")"
    if [[ ${result} = "true" ]]; then
        display --indent 6 --text "- is_wp_project result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- is_wp_project" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

}
