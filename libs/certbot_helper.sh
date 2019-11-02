#!/bin/bash
#
# Autor: broobe. web + mobile development - https://broobe.com
# Script Name: Broobe Utils Scripts
# Version: 3.0
################################################################################
#
# Ref: https://certbot.eff.org/docs/using.html
#

### Checking some things
if [[ -z "${SFOLDER}" ]]; then
  echo -e ${RED}" > Error: The script can only be runned by runner.sh! Exiting ..."${ENDCOLOR}
  exit 0
fi
################################################################################

source ${SFOLDER}/libs/commons.sh
source ${SFOLDER}/libs/packages_helper.sh

################################################################################

certbot_certificate_install() {

  #$1 = EMAIL
  #$2 = DOMAINS

  EMAIL=$1
  DOMAINS=$2

  certbot --nginx --non-interactive --agree-tos --redirect -m ${EMAIL} -d ${DOMAINS}

}

certbot_certificate_force_install() {

  #$1 = EMAIL
  #$2 = DOMAINS

  EMAIL=$1
  DOMAINS=$2

  certbot --nginx --non-interactive --agree-tos --redirect -m ${EMAIL} -d ${DOMAINS}

}

certbot_certificate_renew() {

  #$1 = DOMAINS

  DOMAINS=$1

  certbot renew -d ${DOMAINS}

}

certbot_certificate_force_renew() {

  #$1 = DOMAINS

  DOMAINS=$1

  certbot renew --force-renewal -d ${DOMAINS}

}

# TODO: habria que ver como implementar las pruebas con dry-run
certbot_renew_test() {

  #$1 = DOMAINS

  DOMAINS=$1

  certbot renew --dry-run -d ${DOMAIN}

}

certbot_helper_installer_menu() {

  CB_INSTALLER_OPTIONS="01 INSTALL_WITH_NGINX 02 INSTALL_WITH_CLOUDFLARE"
  CHOSEN_CB_INSTALLER_OPTION=$(whiptail --title "CERTBOT INSTALLER OPTIONS" --menu "Please choose an option:" 20 78 10 $(for x in ${CB_INSTALLER_OPTIONS}; do echo "$x"; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    if [[ ${CHOSEN_CB_INSTALLER_OPTION} == *"01"* ]]; then
      certbot_certificate_install "${MAILA}" "${DOMAINS}"
      #certbot_helper_installer_menu

    fi
    if [[ ${CHOSEN_CB_INSTALLER_OPTION} == *"02"* ]]; then
      certbot_certonly "${MAILA}" "${DOMAINS}"
      #certbot_helper_installer_menu

    fi

  fi

}

certbot_helper_menu() {

  CERTBOT_OPTIONS="01 INSTALL_CERTIFICATE 02 FORCE_INSTALL_CERTIFICATE 03 RECONFIGURE_CERTIFICATE 04 RENEW_CERTIFICATE 05 FORCE_RENEW_CERTIFICATE 06 DELETE_CERTIFICATE 07 SHOW_INSTALLED_CERTIFICATES"
  CHOSEN_CB_OPTION=$(whiptail --title "CERTBOT MANAGER" --menu "Please choose an option:" 20 78 10 $(for x in ${CERTBOT_OPTIONS}; do echo "$x"; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    DOMAINS=$(whiptail --title "CERTBOT MANAGER" --inputbox "Insert the domain and/or subdomains that you want to work with. Ex: broobe.com,www.broobe.com" 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then

      if [[ ${CHOSEN_CB_OPTION} == *"01"* ]]; then
        certbot_helper_installer_menu
        #certbot_helper_menu

      fi
      if [[ ${CHOSEN_CB_OPTION} == *"02"* ]]; then
        certbot_certificate_force_install "${MAILA}" "${DOMAINS}"
        #certbot_helper_menu

      fi
      if [[ ${CHOSEN_CB_OPTION} == *"03"* ]]; then
        # TODO: en teoria instalando normal y luego apretando 1 lo reconfigurás...
        certbot --nginx --non-interactive --agree-tos --redirect -m ${MAILA} -d ${DOMAINS}
        #certbot_helper_menu

      fi
      if [[ ${CHOSEN_CB_OPTION} == *"04"* ]]; then
        certbot_certificate_renew "${DOMAINS}"
        #certbot_helper_menu

      fi
      if [[ ${CHOSEN_CB_OPTION} == *"05"* ]]; then
        certbot_certificate_force_renew "${DOMAINS}"
        #certbot_helper_menu

      fi
      if [[ ${CHOSEN_CB_OPTION} == *"06"* ]]; then
        certbot_certificate_delete "${DOMAINS}"
        #certbot_helper_menu

      fi
      if [[ ${CHOSEN_CB_OPTION} == *"07"* ]]; then
        certbot_show_certificates_info
        #certbot_helper_menu

      fi

      #echo -e ${GREEN}" > Everything is DONE! ..."${ENDCOLOR}

    fi

  else
    exit 1

  fi

}

certbot_certonly() {

  # ATENCION: creo que el mejor camino es correr primero el certbot --nginx y luego el certbot certonly
  # por que el certbot --nginx ya te modifica los archivos de configuracion de nginx y agrega los .pem etc
  # entonces al quedar ya agregados luego el certonly solo pisa esos .pem pero las referencias a esos archivos
  # ya quedaron en los archivos de conf de nginx

  # Ref: https://mangolassi.it/topic/18355/setup-letsencrypt-certbot-with-cloudflare-dns-authentication-ubuntu/2

  # $1 = EMAIL
  # $2 = DOMAINS (domain.com,www.domain.com)

  EMAIL=$1
  DOMAINS=$2

  certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare.conf -m ${EMAIL} -d ${DOMAINS} --preferred-challenges dns-01

  # TODO: probar con: --non-interactive --agree-tos --redirect
  # certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare.conf --non-interactive --agree-tos --redirect -m ${EMAIL} -d ${DOMAINS} --preferred-challenges dns-01

  # TODO: checkear si es necesario cronear renovación
  # por que en teoría ahora el certbot te instala ya acá: /etc/cron.d/certbot una renovación automática

  # 14 5 * * * certbot renew --quiet --post-hook "systemctl reload nginx" > /dev/null 2>&1

  echo -e ${CYAN}"Now you need to follow the next steps:"${ENDCOLOR}
  echo -e ${CYAN}"1- Login to your Cloudflare account and select the domain we want to work."${ENDCOLOR}
  echo -e ${CYAN}"2- Go to de 'DNS' option panel and Turn ON the proxy Cloudflare setting over the domain/s"${ENDCOLOR}
  echo -e ${CYAN}"3- Go to 'SSL/TLS' option panel and change the SSL setting from 'Flexible' to 'Full'."${ENDCOLOR}

}

certbot_show_certificates_info() {

  #CERT_DOMAINS=$(certbot certificates |& grep Domains | cut -d ':' -f2)
  #CERT_DOMAINS_EXP=$(certbot certificates |& grep Expiry | cut -d ':' -f2)

  certbot certificates

}

certbot_certificate_delete() {

  # $1 = DOMAINS (domain.com,www.domain.com)

  DOMAINS=$1

  while true; do
    echo -e ${YELLOW}"> Do you really want to delete de certificates for ${DOMAINS}?"${ENDCOLOR}
    read -p "Please type 'y' or 'n'" yn

    case $yn in
    [Yy]*)
      certbot delete --cert-name ${DOMAINS}
      break
      ;;
    [Nn]*)
      echo -e ${YELLOW}"Aborting ..."${ENDCOLOR}
      break
      ;;
    *) echo " > Please answer yes or no." ;;
    esac

  done

}