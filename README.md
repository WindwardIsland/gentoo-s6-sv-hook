## Purpose
When following online guides on how to switch your init system on Gentoo from OpenRC to others (e.g. [to s6](https://wiki.gentoo.org/wiki/User:Capezotte/s6_on_Gentoo)), you may come across an inevitable problem: once I've fully switched over, **where do I retrieve the actual services for that init?**

Thankfully, Artix Linux (an Arch-based non-SystemD distro) provides services for the four most well-known alternative inits: runit, OpenRC, s6, and dinit. In the case of s6, Artix sources the services from two main places:

- [`s6-scripts`, which provide essential s6-rc oneshots and longruns for startup/shutdown](https://gitea.artixlinux.org/artix/s6-scripts)
- [`s6-services`, which provide s6-rc services for certain packages, e.g. NetworkManager](https://gitea.artixlinux.org/artix/s6-services/)

Typically on Artix, the process of installing and removing these services is automated with the use of [PKGBUILDs](https://wiki.archlinux.org/title/PKGBUILD). Take a look at the following:

- For the [`s6-scripts` PKGBUILD](https://gitea.artixlinux.org/packages/s6-scripts/src/branch/master/PKGBUILD), the corresponding repository is cloned. `make install` is then run in order to copy all the services to where they should be (typically either `/etc/s6/sv/` or `/etc/s6/adminsv/`). This is typically a one-time operation and is already automated by running the aforementioned command.

- For `s6-services`, typically the package name followed by an indication of the init (e.g. [`networkmanager-s6`](https://gitea.artixlinux.org/packages/networkmanager-s6/src/branch/master/PKGBUILD)) is installed. This then clones the corresponding repository and runs a script to place the necessary service where it should be located (`/etc/s6/sv`).

On Gentoo, hooks paired with Portage/`emerge` can be used to automate this process in a similar way. This project will mainly focus on automating installing and removing services for *custom installed* packages.

## Installation
> [!TIP]
> While you can switch your init from OpenRC to s6 (or really to any init) using the aforementioned guide *after* installation, it is much easier to switch *during* installation as you would have less packages installed, less service scripts installed, and overall less overhead to deal with than a fully installed Gentoo system with OpenRC.

1. Copy `bashrc` over to `/etc/portage`. This file contains functions that will run the script (`s6-sv-hook`) with certain options depending if a package is installed or removed. The corresponding service will then be installed or removed, respectively. **Do not** make the file executable, as it will be *sourced* by Portage, *not run*.
2. Copy `s6-sv-hook` over to `/usr/bin` (so it's in your `PATH`). This is the script that will be called by the hook functions in `/etc/portage/bashrc`. Remember to make the script executable.

## Mechanism
### `bashrc`
- `post_pkg_postinst()` is a hook function that will run after a package has been *installed*.
- `post_pkg_postrm()` is a hook function that will run *after* a package has been *removed*.
- In the hooks, `|| true` is needed so that the package will still succeed in being installed or removed, even though those failed for its corresponding service. `s6-sv-hook` will output errors as to why those happened.

### `s6-sv-hook`
This script has two main options:
- `-i`: This runs the `install()` function, with the specified package name as an argument. This will check the Artix `world` repository to see if this package has a corresponding s6 service, and then installs it. If no service was found, the script will abort with exit code 1.
- `-r`: This runs the `remove()` function, with the specified package name as an argument. This will check if the service has already been installed, and if it has, it will be removed. If the service wasn't installed previously, the script will abort with exit code 1.

## Sources
- [Gentoo Wiki on Portage hooks](https://wiki.gentoo.org/wiki/Handbook:Parts/Portage/Advanced#Hooking_into_the_emerge_process)
- [Gentoo Dev docs on ebuild phase hooks](https://dev.gentoo.org/%7Ezmedico/portage/doc/portage.html#config-bashrc-ebuild-phase-hooks)
- [The available ebuild phases to build hooks around](https://dev.gentoo.org/%7Ezmedico/portage/doc/portage.html#package-ebuild-phases)
- [Gentoo Wiki on `/etc/portage/bashrc`](https://wiki.gentoo.org/wiki//etc/portage/bashrc)
