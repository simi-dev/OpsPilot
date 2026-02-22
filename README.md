# OpsPilot 🚀

OpsPilot is a lightweight, zero-dependency system auditing tool for Linux. It provides a quick overview of system health, resource usage, and security status.

## Features

- **System Info**: Hostname, OS distribution, Kernel version, and Uptime.
- **Resource Monitoring**: CPU load, Memory usage (with color-coded alerts), and Disk usage.
- **Network Audit**: Local IP address, Gateway, and a list of active listening ports.
- **Security Check**: Sudo users list, failed SSH login attempts, and firewall status (UFW).
- **Remote Auditing**: Audit remote servers over SSH with a single command.
- **JSON Support**: Structured output for integration with other tools.

## Requirements

- Bash
- Common Linux utilities (`awk`, `grep`, `hostname`, `uname`, `uptime`, `free`, `df`, `nproc`, `ip`, `ss`, `getent`)
- `sudo` privileges for some network and firewall checks.

## Usage

### Local Audit

To run a local audit with pretty-printed output:

```bash
bash audit.sh
```

### Remote Audit

To audit a remote server (the script copies itself to the target and runs):

```bash
bash audit.sh --remote user@remote-host
```

### JSON Output

For machine-readable output:

```bash
bash audit.sh --json
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
