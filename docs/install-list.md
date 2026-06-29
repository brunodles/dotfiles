# Install List — Package Configuration DSL

> Este arquivo era originalmente um script shell (`scripts/install_list.sh`) com uma DSL
> de instalação multiplataforma. Foi movido para `docs/` porque o interpretador
> (`install/interpreter.sh`) nunca foi implementado — o conteúdo é a **documentação do plano**,
> não um script executável.

**Author:** Bruno de Lima <github.com/brunodles>

## Visão Geral

A configuração é tanto uma documentação quanto uma tabela de 3 colunas:

| Coluna | Descrição |
|--------|-----------|
| 1 | Chave da plataforma (ex: `Ar` para Arch Linux, `Ud` para Ubuntu Desktop) |
| 2 | Comando (alias ou comando real) |
| 3 | Pacotes ou parâmetros |

---

## Chaves de Plataforma

| Key | System |
|-----|--------|
| `Ar` | Arch Linux |
| `Ap` | Alpine Linux |
| `Ud` | Ubuntu Desktop |
| `Us` | Ubuntu Server |
| `R`  | Raspbian |
| `Rd` | Raspbian Desktop |
| `Rs` | Raspberry Server |
| `M`  | MacOS (brew) |
| `*`  | Todas as plataformas |

## Aliases de Comando

| Key | Comando |
|-----|---------|
| `i` | Instala usando o gerenciador da plataforma (`apt install`, `pacman -S`, `apk add`, `brew install`) |
| `cask` | MacOS apenas — `brew install --cask` |
| `*` | Qualquer outro comando é executado literalmente |
| `?` | Recipes customizadas em `recipes/` podem sobrescrever o comando install |

---

## Pre install

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ud, Us | `sudo apt update` | |
| Ud | `i` | `snapd` |
| Ud | `snap` | `snap-store` |
| Ud | `echo` | `"Snap store installed"` |

## Terminal / Shell

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ud, Us | `i` | `build-essential` |
| Ar | `i` | `base-devel` |
| `*` | `i` | `curl wget git` |
| `*` | `i` | `vim` |
| `*` | `i` | `neovim` |
| M | `cask` | `neovim` |
| `*` | `i` | `tmux` |
| `*` | `i` | `zsh` |
| `*` | `i` | `oh-my-zsh` |
| `*` | `echo` | `"Terminal shell installed"` |

## File System

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar, Ap, Ud, Us | `i` | `samba` |
| Ar, Ap, Ud, Us | `i` | `unzip` |

### USB + Disk Management

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar, Ud | `i` | `udisks2` |
| Ar, Ud | `i` | `usbutils` |
| Ar, Ud | `i` | `sshfs` |
| Ar | `i` | `gvfs gvfs-smb` |
| `*` | `echo` | `"File system"` |

## Ghostty

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar | `pacman` | `ghostty` |
| M | `cask` | `ghostty` |
| Ud | `snap` | `ghostty --classic` |

## Containers

### Docker
> ⏸️ Desabilitado — precisa pensar em como declarar scripts de instalação customizados.
> Processo complexo. Substituído por Podman.

```yaml
# * i docker docker-compose-plugin
# * i docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Podman

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar | `i` | `arch-install-scripts` |
| Ar, Ud | `i` | `lxc podman` |

## UI Customization / Desktop Environment

### i3wm

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar, Ud | `i` | `firefox feh i3 i3blocks` |

> `compton` está comentado: `#au i compton`

### File Manager

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar, Ud | `i` | `thunar thunar-volman thunar-archive-plugin` |

### Network & Bluetooth Managers

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar, Ud | `i` | `network-manager network-manager-applet` |
| Ar, Ud | `i` | `blueman` |

### Hyprland

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ud | `i` | `hyprland wofi dolphin hyprpaper` |

### Monitor / Display Manager

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar | `i` | `xorg-xrandr` |
| Ud | `i` | `x11-xserver-utils` |

### Graphical Libraries

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar | `i` | `glu webkit2gtk-4.1` |
| Ud | `i` | `libglu1-mesa libwebkit2gtk-4.1-dev` |
| Ar, Ud | `i` | `fonts` |

### Alacritty

> Comentado: `#au i alacritty` — precisa pensar em como declarar scripts customizados.

## Android

| Plataforma | Comando | Pacote / Parâmetro |
|------------|---------|-------------------|
| Ar, Ud | `i` | `scrcpy` |

> `pidcat-git` comentado (`#aum i pidcat-git`)

---

## Notas

- Este DSL **nunca foi implementado** — não existe `install/interpreter.sh`.
- A intenção era ter um interpretador que lesse este arquivo, detectasse a plataforma atual,
  e executasse apenas as linhas aplicáveis.
- Enquanto o interpretador não existe, os bootstrap scripts chamam os scripts em `install/` diretamente.
- O formato de tabela na verdade era um script shell com linhas executáveis intercaladas
  com comentários-documentação — o interpretador precisaria pular linhas de documentação
  (começando com `#`) e executar o resto.
