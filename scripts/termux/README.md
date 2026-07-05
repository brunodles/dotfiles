# scripts/termux — Termux utilities compartilhadas

Scripts e configs do Termux que funcionam em qualquer host Android
no homelab — tanto `android_server` quanto `phone`.

## Estrutura

```
scripts/termux/
├── bin/
│   ├── termux-ip          ← Mostra IP local e público
│   ├── termux-notify      ← Envia notificação Android
│   └── termux-wake        ← Adquire wakelock (evita Doze)
├── termux.properties      ← Extra keys, tema escuro
└── README.md
```

## Uso

Os scripts esperam estar no `$PATH`. Cada host bootstrap copia
os que precisa para `~/.local/bin/`.

Dependências: `termux-api` (pkg install termux-api).
