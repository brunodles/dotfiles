# Android (Termux)

Dispositivo Android rodando Termux como servidor no homelab.

Run `bootstrap.sh` to set up the device.

## Packages instalados via `pkg`

- `zsh` — shell principal
- `oh-my-zsh` — framework de plugins
- `tmux` — multiplexador de terminal
- `openssh` — servidor SSH
- `git`, `curl`, `wget` — ferramentas base
- `neovim`, `python`, `nodejs` — dev tools
- `termux-services` — gerenciamento de daemons (sshd via `sv`)
- `termux-api` — wake lock, notificações, sensor de bateria
- `openssl-tool` — utilitários criptográficos

## Serviços Rodando

| Serviço | Gerenciado por | Porta |
|---------|---------------|-------|
| SSH     | `sv` (termux-services) | 8022 |

## Scripts Disponíveis

| Script | Função |
|--------|--------|
| `termux-wake` | Mantém CPU ativa (wakelock) |
| `termux-sleep` | Libera wakelock |
| `termux-notify` | Envia notificação Android |
| `termux-battery-status` | Monitora nível da bateria |
| `termux-ip` | Mostra IP local e público |
| `termux-ssh-tunnel` | Cria túnel SSH reverso pro homelab |
