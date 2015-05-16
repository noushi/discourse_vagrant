
# Unattended Discourse 

This repository provides a fully unattended Discourse install using `provision.sh` following [the official Discourse installation method](https://github.com/discourse/discourse/blob/master/docs/INSTALL-cloud.md).


You can also test it in vagrant.

Custom variables can be defined in `config`:

- the variables mentioned in [INSTALL-cloud.md](https://github.com/discourse/discourse/blob/master/docs/INSTALL-cloud.md) are covered
- any other variable defined in `containers/app.yml` can be added
- `DEFAULT_PASSWORD` is the password that is set for every email in `DISCOURSE_DEVELOPER_EMAILS`

Server hostname will be changed to the value of `DISCOURSE_HOSTNAME` in `config`.

# Usage

1. Change `config` to fit your needs.

2. Either:
   i. run `provision.sh` and access Discourse on port 80
   i. run `vagrant up` and access Discourse on port 8080

3. connect to Discourse using the email(s)/password stored in `DISCOURSE_DEVELOPER_EMAILS` and `DEFAULT_PASSWORD`

4. profit!

# Supported OSes

- `Ubuntu 14.04LTS`
- Any recent Debian-based distro **should** work

