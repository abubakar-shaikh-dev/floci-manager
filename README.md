# Floci Manager

**A one-key menu for [Floci](https://github.com/floci-io/floci) on Windows.**
Start local AWS, make S3 buckets, upload files. No commands to remember.

![Floci Manager screenshot](docs/banner.jpg)

> Unofficial tool. Not made by or connected to the Floci team.

---

## Why use it?

Floci runs a free fake AWS on your computer. The commands are easy, but typing them again and again is boring. This menu does it for you with **one key press**.

- Start and stop Floci
- Keep your data between restarts
- Make, list and delete S3 buckets
- Upload files (drag and drop works)
- Open the web console
- Health check when something breaks
- Safe delete: you must type the bucket name first

## What you need

| Thing | Why | Get it |
|---|---|---|
| Windows 10 or 11 | Colors and `curl` | |
| Docker Desktop | Floci runs in Docker | [docker.com](https://www.docker.com/products/docker-desktop/) |
| Floci CLI | Starts Floci | See below |
| AWS CLI | Only for the bucket menu | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |

Install the Floci CLI (PowerShell):

```powershell
iwr https://floci.io/install.ps1 | iex
```

## How to use

1. Download `floci-manager.bat` from the [latest release](https://github.com/abubakar-shaikh-dev/floci-manager/releases/latest), or clone:

   ```bash
   git clone https://github.com/abubakar-shaikh-dev/floci-manager.git
   ```
2. Open Docker Desktop and wait until it says **running**.
3. Double-click `floci-manager.bat`.
4. Press **S** to start Floci.

That is all.

## Keys

| Key | What it does |
|---|---|
| **S** | Start (fresh, nothing saved) |
| **K** | Start and keep my data (saved in the `data` folder) |
| **X** | Stop |
| **I** | Status |
| **L** | Logs (last 50 lines) |
| **H** | Health check |
| **B** | List buckets |
| **N** | New bucket |
| **F** | Files in a bucket |
| **U** | Upload a file |
| **R** | Remove a bucket |
| **W** | Open web console |
| **C** | Connection details |
| **Q** | Quit |

Keys that cannot work right now (for example **B** when Floci is stopped) are shown in grey.

## Use your own port

Default port is `4566`. To change it:

```bat
set FLOCI_PORT=4599
floci-manager.bat
```

## Connect your code

Press **C** in the menu to see everything. The short version:

```
Endpoint    http://localhost:4566
Access key  test
Secret key  test
Region      us-east-1
```

In your code, turn on **path-style S3 addressing**.

## Problems?

| Problem | Fix |
|---|---|
| "Floci CLI not found" | Install it (see above), then open the file again |
| "Docker is not running" | Start Docker Desktop and wait |
| Start fails | Press **H** for the health check |
| Port already in use | Press **X** to stop. It also frees the port |
| Strange symbols instead of boxes | Use Windows Terminal, or update Windows |
| "AWS CLI not found" | Install AWS CLI. Only the bucket menu needs it |

## Contributing

Pull requests are welcome. Please:

- Save `.bat` files as **UTF-8 without BOM**
- Keep **CRLF** line endings (the repo does this for you via `.gitattributes`)
- Keep the text short and simple

## License

[MIT](LICENSE)
