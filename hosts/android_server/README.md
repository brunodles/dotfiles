# Android Server (Termux)

Android device running termux as a server.

This device will also act as redundancy of the DNS running on raspberry pi (pihole), in cases of power outage.
SO the router can point only to internal devices.

Run `bootstrap.sh` to set up the device.

## TTS (Text-to-Speech)

A `termux-tts-server` HTTP endpoint is available to speak text aloud
via the device speaker. Managed as a runit service (`ttsd`).

```bash
# Speak a message
curl -X POST http://<android-ip>:<port>/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Alerta no servidor"}'

# Find the port
cat ~/.termux/ttsd-port

# Service management
sv status ttsd
sv restart ttsd
```
