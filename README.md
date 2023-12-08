<img src="static/logo.png" width="250" height="156" alt="Mac Dev Playbook Logo" />

# Mac Development Ansible Playbook

Automate mac dev environment setup with ansible

## Quickstart
```bash
# install dependencies
make install
python -m pip install ansible ansible-lint

# run playbook
# * become (sudo)
# * askpass
# * tags: foo,bar
# * verbose
# * limit to group/single host
ansible-playbook tasks/pkg.yml -b -K --<tags|skip-tags> qa -vvv --limit 'control_plane:control-plane@orb'
```

## TODO
* [Issues](https://github.com/pythoninthegrass/mac_dev_playbook/issues)

## Further Reading
[OG Author - Jeff Geerling](https://github.com/geerlingguy/mac-dev-playbook)

[Tart](https://github.com/cirruslabs/tart)
