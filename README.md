# terraform-ansible-primer
Terraform + Ansible = &lt;3

## About

This is a terraform and ansible primer repo that I've setup for myself to use terraform to deploy EC2 instances and dump the instance details to a ansible inventory file using terraforms `local_file` resource. Then use ansible to deploy my ansible playbook to the target instances.

_Related_: If you would like to use Hashicorp Packer to install the software with ansible, create the AMI and let Terraform use that AMI, checkout my [terraform-packer-ansible-nginx-basic](https://github.com/ruanbekker/terraform-packer-ansible-nginx-basic) github project.

## Rundown

This demonstration does the following:

1. EC2 instance with an extra EBS volume (Terraform)
2. Ansible to format and mount the EBS volume and install Docker (Ansible)

In detail:

- Terraform:
  - Fetches the latest `ubuntu-focal-20.04` AMI from Canonical
  - Fetches the existing VPC details by tag (`Key:Name, Value:main`)
  - Fetches a list of subnet id's within the VPC tagged (`Key:Tier, Value:public`) and shuffles it and returns one subnet id
  - Create a SSH keypair from our public key: `~/.ssh/id_rsa.pub`
  - Create an additional EBS volume
  - Create a Security Group which allows port `22`
  - Create a EC2 instance and reference the above outputs
  - Generate a ansible invetory file to `ansible/inventory` from the `templates/inventory.tmpl` template using the `local_file` resource in `ansible.tf`

- Ansible:
  - Our `ansible.cfg` is set to `inventory = ansible/inventory` so it will by default reference our generated inventory
  - We run our ansible playbook to format and mount our EBS volume and install docker.

## Assumptions

If you would like to use this as a template, the following might need to be change to suite your environment:

- AWS Profile: mine is set to `personal` in `~/.aws/credentials` which in terraform is defined in `providers.tf`.
- VPC Name: I'm using my default VPC and my `Name` tag is set to `main`.
- Subnet IDs: I'm using public subnets, and my public subnets are tagged `Tier` to `public`.
- SSH Key: I'm using my `id_rsa` key, which the public key is located at `/Users/ruan/.ssh/id_rsa.pub` and defined in `main.tf`.
- Variables can be inspected in `variables.tf`.
- My naming convention follows a `namespace` which is defined in `locals.tf` and is built by `"${var.environment_name}-${var.project_name}"` as a prefix.
- Review `ansible.tf` to see how the `ansible/inventory` will be generated.

## Usage

Initialize terraform by fetching the provider data, etc:

```bash
$ terraform init
...
Terraform has been successfully initialized!
```

Then to see the execution plan that will be built by terraform:

```
$ terraform plan
...
  # aws_key_pair.deployer will be created
  + resource "aws_key_pair" "deployer" {
      + arn             = (known after apply)
      + fingerprint     = (known after apply)
      + id              = (known after apply)
      + key_name        = "deployer-key"
      + key_name_prefix = (known after apply)
      + key_pair_id     = (known after apply)
      + public_key      = "ssh-rsa AAA[masked]]ZEE= ruan@terraform-example"
      + tags_all        = (known after apply)
    }

...
Plan: 9 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + account_id      = "xxxxxxxxxxxxx"
  + ansible_command = "ansible-playbook ansible/playbook.yml"
  + az              = (known after apply)
  + id              = (known after apply)
  + ip              = (known after apply)
  + subnet          = (known after apply)
```

Once you are happy with the output, you can deploy your infrastructure:

```bash
$ terraform apply
...
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

account_id = "xxxxxxxxxxxx"
ansible_command = "ansible-playbook ansible/playbook.yml"
az = "af-south-1b"
id = "i-016b66b2471c6b405"
ip = "13.245.92.13"
subnet = "subnet-b06166c8"
```

When we look at the generated file `ansible/inventory` that was created by terraform from the template `templates/inventory.tmpl` which is used by terraform in `ansible.tf`, we can see it has been populated with our EC2 instances details:

```bash
[instance]
dev-ephemeral ansible_host=13.245.149.125 ansible_connection=ssh ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa # i-0cf13c7b8a00e387d
```

We can test the deployed instance with Ansible to verify connectivity:

```bash
$ ansible all -m ping
Enter passphrase for key '/Users/ruan/.ssh/id_rsa': 
dev-ephemeral | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

We can also test using SSH:

```bash
$ ssh ubuntu@13.245.149.125 uptime
Enter passphrase for key '/Users/ruan/.ssh/id_rsa': 
 13:19:55 up 4 min,  0 users,  load average: 0.05, 0.11, 0.06
```

Deploy the software to the EC2 instance with Ansible, defined in the playbook `ansible/playbook.yml` which will format and mount our extra disk, and install docker:

```bash
$ ansible-playbook ansible/playbook.yml
...

PLAY RECAP ***********************************************************************************************************************************************************
dev-ephemeral              : ok=27   changed=13   unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
```

We can SSH to our instance to validate that our first ansible role mounted our disk to the path `/data`:

```bash
$ ssh ubuntu@13.245.92.13
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        20G  2.1G   18G  11% /
/dev/nvme1n1     20G  176M   20G   1% /data
```

And then validate that our second role was executed to install docker:

```bash
$ docker version
Client: Docker Engine - Community
 Version:           20.10.13
 API version:       1.41
 Go version:        go1.16.15
 Git commit:        a224086
 Built:             Thu Mar 10 14:07:51 2022
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.13
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.16.15
  Git commit:       906f57f
  Built:            Thu Mar 10 14:05:44 2022
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.5.10
  GitCommit:        2a1d4dbdb2a1030dc5b01e96fb110a9d9f150ecc
 runc:
  Version:          1.0.3
  GitCommit:        v1.0.3-0-gf46b6ba
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

$ exit
```

If we want to use ansible to gather the remote instance's facts:

```
$ ansible all -m gather_facts
...
dev-ephemeral | SUCCESS => {
    "ansible_facts": {
        "ansible_architecture": "x86_64",
        "ansible_bios_vendor": "Amazon EC2",
        "ansible_board_asset_tag": "i-016b66b2471c6b405",
    ...
    }
}
```

To destroy our infrastructure:

```
$ terraform destroy
...
Destroy complete! Resources: 9 destroyed.
```