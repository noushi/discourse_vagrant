#!/bin/bash

bootstrap_reqs() {
    apt-get -yy install realpath
}

set_base_dir() {
    if [ "$0" = /tmp/vagrant-shell ] ; then
	BASE_DIR=/vagrant
    else
	BASE_DIR=$( realpath $(dirname $0) )
    fi
    
    echo setting basedir as $BASE_DIR
}

set_config() {
    CONFIG=$BASE_DIR/config
    
    . $CONFIG
}

in_discourse() { cd /var/discourse ; "$@" ; cd - ; }
in_dockermail() { cd /var/dockermail ; "$@" ; cd - ; }

install_reqs() {
    apt-get update
    apt-get -yy install git realpath make expect debconf-utils
}

install_discourse_reqs() {
    echo "unattended-upgrades     unattended-upgrades/enable_auto_updates boolean true"  | sudo debconf-set-selections
    apt-get -yy install unattended-upgrades 

    apt-get -yy install libpam-cracklib

    apt-get -yy install python3-xtermcolor python3-yaml
}

install_compose() {
    curl -L https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

add_docker_powers() {
    for user in vagrant ubuntu ; do
	adduser $user docker || true
    done
}

setup_hostname() {
    echo "$DISCOURSE_HOSTNAME" >/etc/hostname
    service hostname restart
}

setup_hosts() {
    echo -e "127.0.0.1\t$DISCOURSE_HOSTNAME" >>/etc/hosts
}

setup_dockermail() {
    mkdir -p /var/dockermail

    git clone https://github.com/lava/dockermail /var/dockermail

    # expose rainloop
    in_dockermail sed -i 's|127.0.0.1:33100:80|0.0.0.0:33100:80|' Makefile

    in_dockermail make
}

start_dockermail() {
    in_dockermail make run-all
}

setup_mailcatcher() {
    apt-get install -yy build-essential ruby-dev libsqlite3-dev
    gem install mailcatcher
}

start_mailcatcher() {
    mailcatcher --ip 0.0.0.0
}

install_docker() {
    docker -v || wget -qO- https://get.docker.com/ | sh
}

install_discourse() {
    mkdir -p /var/discourse
    
    git clone https://github.com/discourse/discourse_docker.git /var/discourse
    
    in_discourse cp samples/standalone.yml containers/app.yml
}

configure_app_yml() {
    cat $CONFIG | while IFS='=' read key value ; do
	in_discourse sed -i "s|[#]*$key:.*|$key: '$value'|" containers/app.yml
    done
}

bootstrap_discourse() {
    in_discourse ./launcher bootstrap app    
}

start_discourse() {
    in_discourse ./launcher start app
}

configure_admin_account() {
    for dev in $( echo $DISCOURSE_DEVELOPER_EMAILS | tr ',' ' ' ) ; do
	in_discourse expect  <<EOF 
spawn ./launcher enter app

expect "*-app:/#"
send   "rake admin:create\r"

expect "Email:"
send   "$dev\r"

expect "Password:"
send   "$DEFAULT_PASSWORD\r"

expect "Repeat password:"
send "$DEFAULT_PASSWORD\r"

expect "Do you want to grant Admin privileges to this account? (Y/n)"
send   "Y\r"

interact

EOF
    done
    
}


bootstrap() {
    bootstrap_reqs    
    set_base_dir
    set_config
}

setup_email() {
    setup_hostname
#    setup_dockermail
    setup_mailcatcher
}

start_email() {
#    start_dockermail
    start_mailcatcher
}

prepare_setup() {
    install_reqs
    install_compose
    setup_hosts
    setup_email
    start_email
}

finalize_setup() {
    add_docker_powers
}

setup_discourse() {
    install_discourse_reqs

    install_discourse

    configure_app_yml

    bootstrap_discourse

    start_discourse    

    configure_admin_account
}

fire_up() {
    bootstrap

    prepare_setup

    install_docker

    setup_discourse

    finalize_setup
}

# if __FILE__ == $0
if ! [[ "$0" =~ bash$ ]] ; then
    set -x
    whoami
    [ `whoami` = root ] || sudo "$0" "$@"
    fire_up
fi
