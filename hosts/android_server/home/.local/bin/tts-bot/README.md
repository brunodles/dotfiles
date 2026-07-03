# TTS Bot — Telegram text-to-speech for Android/Termux

Recebe texto ou áudio no Telegram e reproduz no speaker do Android
via Termux. Rodeado por runit no servidor Android.

## Dependencies

```bash
pkg install python termux-api
pip install requests python-dotenv
```

## Setup

```bash
cd ~/.local/bin/tts-bot
cp .env.example .env
```

Preencha `.env`:

| Variable | Onde obter |
|----------|-----------|
| `TELEGRAM_BOT_TOKEN` | [@BotFather](https://t.me/botfather) — crie um bot |
| `ALLOWED_USER_IDS` | [@userinfobot](https://t.me/userinfobot) — seu ID numérico |

## Run

```bash
python ~/.local/bin/tts-bot/main.py
```

Ou via runit (supervisionado):

```
sv up tts-bot
```

## Estrutura

```
tts-bot/
├── main.py        # Entrypoint
├── bot.py         # Polling loop + dispatch
├── tts.py         # TTS speak + audio play
├── env.py         # .env loader
├── .env.example   # Template
├── .gitignore
└── README.md
```
