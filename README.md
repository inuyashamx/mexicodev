# MexicoDev Linux

```
  __  __            _           ____
 |  \/  | _____  __(_) ___ ___ |  _ \  _____   __
 | |\/| |/ _ \ \/ /| |/ __/ _ \| | | |/ _ \ \ / /
 | |  | |  __/>  < | | (_| (_) | |_| |  __/\ V /
 |_|  |_|\___/_/\_\|_|\___\___/|____/ \___| \_/
```

**Linux para Developers** | v0.1.0 "Primera"

Una distribución Linux construida desde cero usando Linux From Scratch 12.2. Optimizada para desarrollo de software.

## Specs

| Componente | Versión |
|---|---|
| Kernel | Linux 6.10.5 |
| Compilador | GCC 14.2.0 |
| Libc | Glibc 2.40 |
| Shell | Bash 5.2.32 |
| Editor | Vim 9.1 |
| SSL | OpenSSL 3.3.1 |
| Python | 3.12.5 |
| Perl | 5.40.0 |
| Arquitectura | x86_64 |

## Instalación

### Requisitos

- PC o VM con al menos 2GB RAM y 10GB disco
- Una USB con cualquier Linux live (Ubuntu, Arch, etc.) para la instalación
- Arquitectura x86_64

### Opción 1: Instalar en VirtualBox / QEMU

#### 1. Crear la VM

**VirtualBox:**
- New → Name: MexicoDev → Type: Linux → Version: Other Linux (64-bit)
- RAM: 2048MB+, Disk: 10GB+ (VDI, dynamic)

**QEMU:**
```bash
qemu-img create -f qcow2 mexicodev.qcow2 10G
```

#### 2. Bootear con un Linux live

Arranca la VM con un ISO de Ubuntu/Arch live.

#### 3. Particionar el disco

```bash
# Identifica el disco (normalmente /dev/sda en VM)
lsblk

# Crear particiones
sudo fdisk /dev/sda
# n → primary → 1 → default → +500M    (boot)
# n → primary → 2 → default → default   (root)
# a → 1                                  (bootable flag)
# w                                      (write)

# Formatear
sudo mkfs.ext2 /dev/sda1
sudo mkfs.ext4 /dev/sda2
```

#### 4. Instalar MexicoDev

```bash
# Montar
sudo mount /dev/sda2 /mnt
sudo mkdir /mnt/boot
sudo mount /dev/sda1 /mnt/boot

# Descargar y extraer (desde GitHub Releases)
wget https://github.com/TU-USUARIO/mexicodev-linux/releases/download/v0.1.0/mexicodev-0.1.0-x86_64.tar.xz
sudo tar xpf mexicodev-0.1.0-x86_64.tar.xz -C /mnt

# Instalar GRUB
sudo mount --bind /dev /mnt/dev
sudo mount -t proc proc /mnt/proc
sudo mount -t sysfs sysfs /mnt/sys

sudo chroot /mnt /bin/bash -c "
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
"

# O si grub no está disponible, usar el config manual:
# Editar /mnt/boot/grub/grub.cfg con las particiones correctas

# Desmontar
sudo umount -R /mnt
```

#### 5. Bootear

Quita el ISO live y reinicia la VM. MexicoDev arrancará.

- **Usuario:** root
- **Password:** (sin password, directo a shell)

### Opción 2: Instalar en hardware real

Mismo proceso que arriba pero:

1. Flashea un Linux live a USB con `dd` o Rufus
2. Bootea tu laptop desde el USB
3. Identifica el disco correcto con `lsblk` (cuidado de no borrar tu disco de Windows)
4. Sigue los pasos 3-5

### Opción 3: Script de instalación automático

```bash
# Desde el Linux live, descarga y corre el instalador:
wget https://raw.githubusercontent.com/TU-USUARIO/mexicodev-linux/main/install.sh
sudo bash install.sh /dev/sdX    # Reemplaza sdX con tu disco
```

## Post-instalación

Una vez dentro de MexicoDev:

```bash
# Configurar password de root
passwd

# Configurar red (si no hay DHCP automático)
ip addr add 192.168.1.100/24 dev eth0
ip route add default via 192.168.1.1
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Verificar el sistema
gcc --version
python3 --version
uname -a
```

## Build from source

Si quieres reconstruir MexicoDev desde cero:

```bash
# Requisitos: Ubuntu/Debian WSL o Linux nativo
sudo apt install build-essential bison gawk m4 texinfo

# Clonar el repo
git clone https://github.com/TU-USUARIO/mexicodev-linux.git
cd mexicodev-linux

# Ejecutar el build completo (~3 horas)
sudo bash build.sh setup
sudo bash build.sh download
sudo bash build.sh toolchain
sudo bash build.sh crosstools
sudo bash build.sh chroot
```

## Estructura del proyecto

```
mexicodev-linux/
├── build.sh              # Script maestro
├── config/
│   ├── distro.conf       # Configuración de la distro
│   └── packages.sh       # Lista de 78 paquetes con URLs
├── scripts/
│   ├── 00-check-host.sh  # Verificar requisitos del host
│   ├── 01-setup-env.sh   # Configurar entorno de build
│   ├── 02-download-sources.sh
│   ├── 03-toolchain.sh   # Cross-toolchain (binutils, gcc, glibc)
│   ├── 04-cross-tools.sh # Herramientas temporales
│   ├── 05-chroot.sh      # Entrar al chroot
│   ├── 06*.sh            # Build de paquetes del sistema
│   ├── 07-system-config.sh
│   └── 08-kernel.sh      # Compilación del kernel
├── install.sh            # Instalador automático
└── README.md
```

## Hecho con

- [Linux From Scratch 12.2](https://www.linuxfromscratch.org/)
- GCC 14.2.0, Glibc 2.40, Linux 6.10.5
- Construido en WSL2 sobre Windows 11

## Licencia

GPLv3 - Los componentes individuales mantienen sus licencias originales.
