# Wip Notice!
This is not fully compatible for auto install and sync.
I'm working on it on my spare time, why I create a better/simplified way to install and sync the configuration files
with the linux home.
I could use gnu/stow, but I'm exploring my own implementation. You might still be able to clone and run `stow home`.

# About this repo

This repo contains the whole setup for each one of my pcs and servers.
This means the Physical and virtual infrastructures are documented.
Each dir have its own purpose, and they might be reused on different places.

| Dir name          | content                                                                         |
|:------------------|---------------------------------------------------------------------------------|
| agents            | contains files relevant for Ai Agents                                           |
| agents/skills     | shared skills to use with any agent                                             |
| dotfiles          | configuration of some apps                                                      |
| hosts             | the configuration of each pc/host, this one perfoms the gluing of other folders |
| scripts           | multi-purpose scripts                                                           |
| scripts/install   | install scripts, might depend on os/platfor/runtime                             |
| scripts/bootstrap | scripts to start some process, preparation scripts                              |
| stacks            | container configuration, runs on some hosts                                     |

# Cloning

This repo should always be cloned into user home

```
~/dotfiles
$HOME/dotfiles
```

Some scripts will use these paths hardcoded, for simplification.
_Accept it._
