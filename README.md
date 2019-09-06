# Build Sentry 🚀

🚀 Users and logs provide clues. Sentry provides answers.

## Links
- [How to build the software](#installation)
- [The build Pipeline](#pipeline)
- [Running the software](#running)

## Installation

You'll need to have [Packer](https://packer.io), [Docker](https://www.docker.com/), [Terraform](https://terraform.io), and [Ansible](https://www.ansible.com/) installed to 
develop/debug the software.  I have a `.gitlab-ci.yml` file that is used to build and provision the container.  This is publicly hosted in my [Docker Hub](https://cloud.docker.com/u/uid0/repository/docker/uid0/ci-tools) account, but
for development purposes, you really don't need it, unless you're making changes to the `.gitlab-ci.yml` file.  




## Pipeline

The pipeline is as follows:

- The `Dockerfile` that is used for build time container can be found in the 'docker' directory.
- Ansible and Packer build an AMI that runs the sentry application.  The Ansible code can be found in the `ansible` directory.
- Cloudformation and Terraform deploy new versions of the application to the cloud.  The tf code can be found in the `tf` directory.
- Terraform configures the sentry application with the redis instance, along with the RDS credentials.

## Release History

* 0.0.1
  * Work in Progress.  It deploys, but it isn't beautiful.


## Meta

Ian Wilson – [@uid0](https://twitter.com/uid0) – hi@ianwilson.org

Distributed under the LGPL v3 license. See ``LICENSE`` for more information.

[https://github.com/uid0](https://github.com/uid0/)

## Contributing

1. Fork it (<https://github.com/uid0/buildsentry/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

## Issues

I'm using Github issues -- if you run into issues, feel free to submit one!

## Hireme

Need a DevOps/Engineering Manager/Architect (more like player/coach than just a coach!)?  Shoot me an email!
