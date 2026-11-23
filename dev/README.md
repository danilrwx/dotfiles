# Development profile

On Ubuntu, `./install --desktop` installs
compilers/build tools, language servers, Node/npm, Go, Go CLIs, kubectl/d8,
Docker, RTK, OpenVPN, QEMU/libvirt and the private agent setup. It links the k9s
configuration and OpenVPN helper, imports private VPN profiles with resolved DNS
and polkit integration, and adds the user to libvirt/KVM groups.

- `./install --android`: also install Android SDK, JDK and Studio.
- `./install --desktop --skip-go`: keep Go tool binaries while updating Go itself.

Go/archive downloads retain their checksum checks and staged replacement.

`godef` is built from `dev/godef` with a pinned `x/tools` dependency that supports
Go 1.27 export data. The upstream source is unchanged; remove the override when
an upstream release includes compatible dependencies.
