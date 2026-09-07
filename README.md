# lockoutserver

Automated setup for a Minecraft 1.21.11 Fabric server on AWS EC2.

## Repo Structure

```
lockoutserver/
├── mods/
│   ├── fabric-api-0.141.3+1.21.11.jar
│   ├── lithium-fabric-0.21.4+mc1.21.11.jar
│   └── lockout-fabric-0.12.2.jar
├── scripts/
│   ├── userdata.sh    # paste into EC2 "User data" at launch
│   ├── start.sh       # start the server
│   └── newworld.sh    # archive current world and generate a new one
└── README.md
```

---

## Creating a New Server

### 1. Launch an EC2 Instance
- **Region:** `ca-central-1` (Canada) or whichever is closest to your players
- **AMI:** Ubuntu Server 24.04 LTS (64-bit x86)
- **Instance type:** `t3.medium` (2 vCPU / 4 GB, small group) or `t3.large` (2 vCPU / 8 GB)
- **Key pair:** select or create one — you need it to SSH in
- **Network settings → Edit → Add security group rule:**
  - Type `Custom TCP`, Port `25565`, Source `0.0.0.0/0` (so your friends can connect)
  - Keep the default SSH rule on port 22
- **Configure storage:** 20 GB gp3 (the default 8 GB fills up fast with worlds)
- **Advanced details → User data:** paste the contents of `scripts/userdata.sh`
- Click **Launch instance**

The instance will automatically install Java, download Fabric, pull the mods and scripts from this repo, and be ready to go by the time it finishes booting (~3–5 min).

### 2. Check Setup Completed
```bash
ssh -i <YOUR_KEY>.pem ubuntu@<YOUR_PUBLIC_IP>
```
```bash
tail -f /var/log/mc-setup.log
```
The last line will read `Setup complete!` when finished. If a mod fails to download or arrives corrupt, setup stops there and the log says which one.

### 3. Start the Server
```bash
bash /home/ubuntu/minecraft/start.sh
```

RAM is allocated automatically (total RAM minus 1 GB reserved for the OS).

Players connect to the instance's **public IPv4 address** on the default port. Note that this address changes every time the instance is stopped and started — attach an Elastic IP if you want it to stay put.

---

## Managing the Server

| Action | Command |
|---|---|
| Start server | `bash /home/ubuntu/minecraft/start.sh` |
| Attach to console | `screen -r mc` |
| Detach from console | `Ctrl + A` then `D` |
| Stop server safely | Attach, then type `stop` |
| New world | `bash /home/ubuntu/minecraft/newworld.sh` |

---

## Starting a New World

```bash
bash /home/ubuntu/minecraft/newworld.sh
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

Go to **EC2 Console → Instances → select the instance → Instance state → Terminate instance**.

> Closing your terminal or stopping the Minecraft process does **not** stop billing. **Stopping** the instance halts compute charges but you still pay for the EBS volume; **terminating** it stops everything and deletes the world. Copy off any worlds you want to keep first.

---

## Updating Mods or Scripts

Push new files to this repo — every new instance launched after that will automatically get the latest versions via `scripts/userdata.sh`.
