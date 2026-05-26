# lockoutserver

Automated setup for a Minecraft 1.21.11 Fabric server on DigitalOcean.

## Repo Structure

```
lockoutserver/
├── mods/
│   ├── fabric-api-0.141.3+1.21.11.jar
│   ├── lithium-fabric-0.21.4+mc1.21.11.jar
│   └── lockout-fabric-0.12.2.jar
├── scripts/
│   ├── start.sh       # start the server
│   └── newworld.sh    # archive current world and generate a new one
├── userdata.sh        # paste into DigitalOcean on droplet creation
└── README.md
```

---

## Creating a New Server

### 1. Create a Droplet
- **Region:** Toronto (TOR1)
- **Image:** Ubuntu 24.04 LTS
- **Size:** 2 vCPU / 4 GB RAM (small group) or 4 vCPU / 8 GB RAM
- **Advanced Options → Add Initialization scripts:** paste the contents of `userdata.sh`
- Click **Create Droplet**

The droplet will automatically install Java, download Fabric, pull the mods and scripts from this repo, and be ready to go by the time it finishes booting (~3–5 min).

### 2. Check Setup Completed
```bash
ssh root@<YOUR_SERVER_IP>
tail -f /var/log/mc-setup.log
```
The last line will read `Setup complete!` when finished.

### 3. Start the Server
```bash
bash /root/minecraft/start.sh
```

RAM is allocated automatically (total RAM minus 1 GB reserved for the OS).

---

## Managing the Server

| Action | Command |
|---|---|
| Start server | `bash /root/minecraft/start.sh` |
| Attach to console | `screen -r mc` |
| Detach from console | `Ctrl + A` then `D` |
| Stop server safely | Attach, then type `stop` |
| New world | `bash /root/minecraft/newworld.sh` |

---

## Starting a New World

```bash
bash /root/minecraft/newworld.sh
```

This will:
1. Warn players in chat
2. Stop the server gracefully
3. Archive the current world as `world_YYYYMMDD_HHMMSS`
4. Start the server fresh with a new world

Old worlds are kept on the server and never deleted automatically.

---

## Client Setup (Players)

- **Required:** Vanilla Minecraft client set to version **1.21.11**
- **Optional (better FPS):** Install a local Fabric 1.21.11 profile and add [Sodium](https://modrinth.com/mod/sodium) to your local `.minecraft/mods/` folder

---

## Teardown (Stop Billing)

Go to **DigitalOcean Dashboard → Droplets → Destroy → Destroy Droplet**.

> Closing your terminal or stopping the Minecraft process does **not** stop billing. You must destroy the droplet.

---

## Updating Mods or Scripts

Push new files to this repo — every new droplet created after that will automatically get the latest versions via `userdata.sh`.
