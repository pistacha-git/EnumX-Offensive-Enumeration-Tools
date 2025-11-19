# WordPress Enumerator v3.0

```text
██╗    ██╗ ██████╗     ███████╗ ███╗   ██╗ ██╗   ██╗ ███╗   ███╗
██║    ██║ ██╔══██╗    ██╔════╝ ████╗  ██║ ██║   ██║ ████╗ ████║
██║ █╗ ██║ ██████╔╝    █████╗   ██╔██╗ ██║ ██║   ██║ ██╔████╔██║
██║███╗██║ ██╔═══╝     ██╔══╝   ██║╚██╗██║ ██║   ██║ ██║╚██╔╝██║
╚███╔███╔╝ ██║         ███████╗ ██║ ╚████║ ╚██████╔╝ ██║ ╚═╝ ██║
 ╚══╝╚══╝  ╚═╝         ╚══════╝ ╚═╝  ╚═══╝  ╚═════╝  ╚═╝     ╚═╝ 
               WordPress Enumeration Framework v3.0
                   Crafted by @pistacha-git
```

Professional WordPress reconnaissance and enumeration framework for authorized penetration testing.

## Description

`wp-enum.sh` is a comprehensive Bash-based tool designed to perform in-depth enumeration of WordPress installations. It employs multiple techniques to gather intelligence about the target site, including version detection, user enumeration, plugin/theme discovery, and security misconfiguration identification.

## 🚀 Features
### Core Enumeration
- **Version Detection** – Multiple methods (meta tags, readme.html, RSS feeds, asset versioning)
- **User Enumeration** – REST API, Author ID iteration, RSS/Atom feeds, XML sitemaps
- **Plugin Discovery** – Homepage source analysis + common plugin probing
- **Theme Detection** – Active theme identification with version extraction
- **Structured Output** – Color-coded terminal output + optional file logging

### 🔐Security Checks
- **XML-RPC Status** – Detects if XML-RPC is enabled (brute force/DDoS vector)
- **Sensitive Files** – Scans for exposed config files, backups, debug logs
- **Directory Listing** – Tests for enabled directory browsing
- **Security Headers** – Analyzes HTTP security headers (HSTS, X-Frame-Options, etc.)
- **SSL/TLS** – Verifies HTTPS usage and HTTP→HTTPS redirection
- **Misconfiguration Scan** – Quick vulnerability assessment

## 🛠️ Requirements

### Dependencies
- `bash` (5.0+)
- `curl` – HTTP requests
- `grep` – Pattern matching
- `awk` – Text processing
- `sed` – Stream editing
- `jq` – JSON parsing (optional but recommended for better REST API parsing)

## 💻 Installation

Clone the repository:
```bash
git clone https://github.com/pistacha-git/EnumX-Offensive-Enumeration-Tools.git
cd EnumX-Offensive-Enumeration-Tools
chmod +x wp-enum.sh
```

## ▶️ Usage
```bash
./wp-enum.sh <target_url> [output_file]
```

⚠️ Legal Disclaimer

This tool is intended exclusively for:

Authorized penetration testing

Educational purposes

Research in controlled environments

Unauthorized use against systems without explicit permission is illegal and unethical.


🧩 Author

Crafted by @pistacha-git

GitHub: https://github.com/pistacha-git


<img width="634" height="528" alt="image" src="https://github.com/user-attachments/assets/42c7bb17-9d9d-44ec-bdae-4b42099bf5c0" />

