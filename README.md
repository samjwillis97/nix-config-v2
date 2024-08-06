# My Nix Configs ❄️

This repository is home to the nix code that builds my systems 🎉.

## Why Nix?

Nix allows for easy to manage, collaborative, reproducible deployments. This means that once something is setup and configured once, it works forever. If someone else shares their configuration, anyone can make use of it.

## How To

### Deploy with deploy-rs

`deploy --remote-build --skip-checks`

### Update Flake Input

`nix flake lock --update-input my-neovim`

### Running NixOS VM on darwin

`nix run .#nixosConfigurations.mac-vm.config.system.build.vm`

copy required keys to `/var/agenix/`, unfortunately this means restarting the VM afterwards, haven't worked out how to copy them there automatically

## Credits

These Repo's are where I took major inspiration and chunks of code from :)

- https://github.com/thiagokokada/nix-configs
- https://github.com/JayRovacsek/nix-config
- https://github.com/domenkozar/homelab

## Nix Components

- https://nixos.org/
- https://github.com/LnL7/nix-darwin
- https://github.com/nix-community/home-manager

## TODOs:

- Look at using proper config and options
- AMD Drivers
- i3 move across monitors

## To Look Into

- https://github.com/ryantm/agenix
- https://github.com/nix-community/nixos-generators
- https://github.com/NixOS/nixos-hardware
- https://nixos.wiki/wiki/Overlays


## Guide to Using

Thanks to https://github.com/MatthiasBenaets/nixos-config, still need to clean up some things to be more about this repo,
and format with markdown.

##  NixOS Installation Guide
This flake currently has *4* hosts
 1. desktop
    - UEFI boot w/ systemd-boot
 2. laptop
    - UEFI boot w/ grub (Dual Boot)
 3. work
    - UEFI boot w/ grub (Dual Boot)
 4. vm
    - Legacy boot w/ grub

Flakes can be build with:
- ~$ sudo nixos-rebuild switch --flake <path>#<hostname>~
- example ~$ sudo nixos-rebuild switch --flake .#desktop~

### Partitioning
This will depend on the host chosen.
#### UEFI
*In these commands*
- Partition Labels:
  - Boot = "boot"
  - Home = "nixos"
- Partition Size:
  - Boot = 512MiB
  - Swap = 8GiB
  - Home = Rest
- No Swap: Ignore line 3 & 7

```bash
  parted /dev/sda -- mklabel gpt
  parted /dev/sda -- mkpart primary 512MiB -8GiB
  parted /dev/sda -- mkpart primary linux-swap -8GiB 100%
  parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
  parted /dev/sda -- set 3 esp
  mkfs.ext4 -L nixos /dev/sda1
  mkswap -L /dev/sda2
  mkfs.fat -F 32 -n boot /dev/sda3
```

#### Legacy
*In these commands*
- Partition Label:
  - Home & Boot = "nixos"
  - Swap = "swap"
- Partition Size:
  - Swap = 8GiB
  - Home = Rest
- No swap: Ignore line 3 and 5

```bash
  parted /dev/sda -- mklabel msdos
  parted /dev/sda -- mkpart primary 1MiB -8GiB
  parted /dev/sda -- mkpart primary linux-swap -8GiB 100%
  mkfs.ext4 -L nixos /dev/sda1
  mkswap -L /dev/sda2
```

### Installation
#### UEFI
*In these commands*
- Mount partition with label ... on ...
  - "nixos" -> ~/mnt~
  - "boot" -> ~/mnt/boot~
```bash
  mount /dev/disk/by-label/nixos /mnt
  mkdir -p /mnt/boot
  mount /dev/disk/by-label/boot /mnt/boot
```

#### Legacy
```bash
  mount /dev/disk/by-label/nixos /mnt
```

#### Mounting Extras
*In these commands*
  - ~/mnt/ssd~
- Label of storage:
  - ssd2
- If storage has no label:
  - ~mount /dev/disk/by-uuid/ssd2 /mnt/ssd~
```bash
  mkdir -p /mnt/ssd
  mount /dev/disk/by-label/ssd2 /mnt/ssd
```

#### Generate
*In these commands*
- Swap is enable:
  - Ignore if no swap or enough RAM
- Configuration files are generated @ ~/mnt/etc/nixos~
  - If you are me, you don't need to do this. Hardware-configuration.nix already in flake.
- Clone repository
```bash
  swapon /dev/sda2
  nixos-generate-config --root /mnt
  nix-env -iA nixos.git
  git clone https://github.com/samjwillis97/nixos-config /mnt/etc/nixos/<name>

  # Optional if you are not me
  cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-config/hosts/<host>/.
```

#### Possible Extra Steps
1. Switch specific host hardware-configuration.nix with generated ~/mnt/etc/nixos/hardware-configuration.nix~
2. Change existing network card name with the one in your system
   - Look in generated hardware-configuration.nix
   - Or enter ~$ ip a~
3. Change username in flake.nix
4. Set a ~users.users.${user}.initialPassword = ...~
   - Not really recommended. It's maybe better to follow last steps
5. If you are planning on using the doom-emacs alternative home.nix, don't forget to rebuild after the initial installation when you link to this nix file.
   - This is because userActivationScript is used for this setup and this will time out during the rebuild.
   - It will automatically install if ~$HOME/.emacs.d~ does not exist
     - If this dir already exist, move or delete it.

#### Install
*In these commands*
- Move into cloned repository
  - in this example ~/mnt/etc/nixos/<name>~
```bash
  cd /mnt/etc/nixos/<name>
  nixos-install --flake .#<host>
```

### Finalization
1. Set a root password after installation is done
2. Reboot without liveCD
3. Login
   1. If initialPassword is not set use TTY:
      - ~Ctrl - Alt - F1~
      - login as root
      - ~# passwd <user>~
      - ~Ctrl - Alt - F7~
      - login as user
4. Optional:
   - ~$ sudo mv <location of cloned directory> <prefered location>~
   - ~$ sudo chown -R <user>:users <new directory location>~
   - ~$ sudo rm /etc/nixos/configuration.nix~ - This is done because in the past it would auto update this config if you would have auto update in your configuration.
   - or just clone flake again do apply same changes.
5. Dual boot:
   - OSProber probably did not find your Windows partition after the first install
   - There is a high likelihood it will find it after:
     - ~$ sudo nixos-rebuild switch --flake <config path>#<host>~
6. Rebuilds:
   - ~$ sudo nixos-rebuild switch --flake <config path>#<host>~
   - For example ~$ sudo nixos-rebuild switch --flake ~/.setup#matthias~

## Nix Installation Guide
This flake currently has *1* host
  1. pacman

The Linux distribution must have the nix package manager installed.
~$ sh <(curl -L https://nixos.org/nix/install) --daemon~
To be able to have an easy reproducible setup when using the nix package manager on a non-NixOS system, home-manager is a wonderful tool to achieve this.
So this is how it is set up in this flake.

### Installation
#### Initial
*In these commands*
- Get git
- Clone repository
- First build of the flake
  - This is done so we can use the home-manager command is part of PATH.

```bash
  nix-env -iA nixpkgs.git
  git clone https://github.com/matthiasbenaets/nixos-config ~/.setup
  cd ~/.setup
  nix build --extra-experimental-features 'nix-command flakes' .#homeConfigurations.<host>.activationPackage
  ./result/activate
```

#### Rebuild
Since home-manager is now a valid command we can rebuild the system using this command. In this example it is build from inside the flake directory:
- ~$ home-manager switch --flake <config path>#<host>~
This will rebuild the configuration and automatically activate it.

### Finalization
*Mostly optional or already correct by default*
1. NixGL gets set up by default, so if you are planning on using GUI applications that use OpenGL or Vulkan:
   - ~$ nixGLIntel <package>~
   - or add it to your aliases file
2. Every rebuild, and activation-script will run to add applications to the system menu.
   - it's pretty much the same as adding the path to XDG_DATA_DIRS
   - if you do not want to or if the locations are different, change this.

## Nix-Darwin Installation Guide
This flake currently has *1* host
  1. macbook

The Apple computer must have the nix package manager installed.
In terminal run command: ~$ sh <(curl -L https://nixos.org/nix/install)~

### Setup
*In these commands*
- Create a nix config directory
- Allow experimental features to use flakes

```bash
  mkdir ~/.config/nix
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Installation
#### Initial
*In these commands*
- Get git
- Clone repository
- First build of the flake on Darwin
  - This is done because the darwin command is not yet available

```bash
  nix-env -iA nixpkgs.git
  git clone https://github.com/matthiasbenaets/nixos-config ~/.setup
  cd ~/.setup
  nix build .#darwinConfigurations.<host>.system
  ./result/sw/bin/darwin-rebuild switch --flake .#<host>
```

~/result~ is located depending on where you build the system.

#### Rebuild
Since darwin is now added to the PATH, you can build it from anywhere in the system. In this example it is rebuilt from inside the flake directory:
- `darwin-rebuild switch --flake .#<host>`
This will rebuild the configuration and automatically activate it.

### Finalization
*Mostly optional or already correct by default*
1. Change default shell for Terminal or iTerm.
   - `Terminal/iTerm > Preferences > General > Shells open with: Command > /bin/zsh`
2. Disable Secure Keyboard Entry. Needed for Skhd.
   - `Terminal/iTerm > Secure Keyboard Entry`
3. Install XCode to get complete development environment.
   - `xcode-select --install`

## Guides
- [[./nixos.org][NixOS general guide]]
- [[./nix.org][Nix on other Linux distributions]]
- [[./darwin.org][Nix on MacOS with Nix-Darwin]]
- [[./contrib.org][Contribution to nixpkgs]]
- [[./shell.org][Using nix shells]]
