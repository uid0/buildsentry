#!/bin/bash

# Make sure git is installed
sudo apt-get install -y git python-pip wget curl
sudo pip install ansible
clear
mkdir .ssh
cat << zzz_end_ssl_certificate_zzz > ~/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA1I/pvbaDWm6D8eDjdQUI87qoYOZeW4DaUNOKhU6fJ+EY3xkm
bjxFP9bS/x1eQaYGTAamgEmyK7MdQDb1ELirLmgUBg3OMSixkUhvgYk1K4F08OBQ
P7Ywa6Nbvk/Vp5UKeJg/LOe7NVxBV4G7EObE7f0MuWoASL6mfxoWq9inMU0fAEaa
qAgvo2BYrQg+fP8PZ2dJCBkQ3Oh3ttf9MemEq/kGW0jsWylB0VNx0m0nsJM7y4wv
MvtPO0pVvgqQWPHL8rhwoTSjTN83MVuiUXZ2ZjUSfn1HaCMNZvBVNfcChmI0ClSa
/tUTSeaqGVLUGkTMtUxpZ6vWhwcdszudR5zWcwIDAQABAoIBAQCwFkQpMBAikxjl
AEsNfs1Ks1+XXl/eZ6DzgjrnchkwvS2Qa9JFUdKALyN9ycNymOnwgzXdYq+hufDK
aHydjI3qlLe5yCf+21o2I46T/ak5UDYi8YApN3FnSd3Pi21QNYyGGIGFXrbcXn+W
0Va5iqKrEI1A8Eop+R4Ofvs3AvSGRn0V0abtLguz5fT65rjPV9wLAyDQe23NBRpw
JD0eC60Mx6r6XqSm7aC2fU9vuP97Z5jf7dtoZUf5kzEiW1CJ5PLPxmfdOCAqhtej
t9lF8tD5j6G6XxJOA3s9ydEfE3nSdNWKQhYUCdKmcYZae2VN9LJvwjxiX0yOuHwn
tVppMH0BAoGBAPX6ZAr5KIQ4PIxz499icuvjf/0cYsFiPdYYzs97Oqiz0uByA/qV
nAxoGcEpZTNZTQWuABbceINqNeU9xWpvc6QZpVSgOmSah/sERbuhW2wzVRbLpmBV
a3V2aSLgjqdyUr6NIU66iKCpHbnPMu3rArg7HBhV9r9hiGq5SHJeSPPzAoGBAN04
/HzC4r1l+TM06fDDwP7qW34X/Oqe7/MAtduCiYSiccrlTjW+xQaT7CzUM9zWercc
OAJ8ZADYk5DuNew7sV7IaN5p+BfIXH8gXudmoE9AwjuZybEZ3do9lL+39b7U3MiG
jXoeOj5Ly4Of7j9rqo0OOmNQi51dEJxjlvkRXbOBAoGATd59i0fDPtA6ws/xRId7
EBgOLYet78B1CPEDj4VYVY3P5UPS5KI2K2tNM+wx4GaVzoV9+77B3ABknXTHqWEs
/7cqsraipbSR9bItjS+QrJk3h6bivb5s7VuV/veN0Y6MiUxOTgkZNZs0EN16Jv1t
9/qmc0HLglyS/g431BTrDWcCgYEAo95smXY7QxTgbaAKksBOnAW51EOso5csIxMp
ovqlJ0y1ghgtwP4ZMHAuiF6ANFvj9vO+QYknAsFrPfZWlzD4iD9n/yj8D5HpgnnW
Ew8gPNS5jDC1CK0ie2EWaJW6QauoCBozfnwZpL+8dznm36+/XFFnyt2FLgIcJdxX
nxPQFwECgYEAhyDWsBiZeD1YJC92EwpTVt4AbKweGX+r0MzRYkUl/jaDzUKX0tW3
wnrsIol8eP3nErZMGSjnptfaTnM25CCmcV2oSyVWHuwlUUjf9mLmX+cbu2gRpEYk
EBCyfysSMtevniqtq+FQwn51uWSyl9rOi2sbIcUMZDsiO+yMmY3UU+s=
-----END RSA PRIVATE KEY-----
zzz_end_ssl_certificate_zzz
chmod 0600 ~/.ssh/id_rsa
sudo mkdir /etc/ansible
cat << zzz_end_hosts_yaml_file_zzz | sudo tee /etc/ansible/hosts
[all] 
localhost
zzz_end_hosts_yaml_file_zzz
ssh-keyscan git.iwcg.io >> ~/.ssh/known_hosts
ansible-pull -U git@git.iwcg.io:uid0/buildsentry.git packer/sentry-server.yml