#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.20
#############################################################################

function test_wpcli_helper_funtions() {

    local project_domain

    project_domain="test.domain.com"

    # TODO: create db and user_db

    # Create mock project
    wpcli_core_download "${SITES}/${project_domain}"

    # Tests
    test_wpcli_get_wpcore_version "${SITES}/${project_domain}"

    test_wpcli_get_db_prefix "${SITES}/${project_domain}"
    
    test_wpcli_change_tables_prefix "${SITES}/${project_domain}"

    test_wpcli_get_db_prefix "${SITES}/${project_domain}"

    # Deleting temp files
    #rm -R "${SITES}/${project_domain}"

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
