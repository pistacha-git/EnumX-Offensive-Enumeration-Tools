```text
██████═╗ ██████╗  ██╗   ██╗ ██████╗  █████╗   ██╗     
██   ██║ ██╔══██╗ ██║   ██║ ██╔══██╗ ██╔══██╗ ██║     
██   ██║ ██████╔╝ ██║   ██║ ██████╔╝ ███████║ ██║     
██   ██║ ██╔══██╗ ██║   ██║ ██╔═══╝  ██╔══██║ ██║     
██████╔╝ ██║  ██║ ╚██████╔╝ ██║      ██║  ██║ ███████╗
╚═════╝  ╚═╝  ╚═╝  ╚═════╝  ╚═╝      ╚═╝  ╚═╝ ╚══════╝

███████╗ ███╗   ██╗ ██╗   ██╗ ███╗   ███╗
██╔════╝ ████╗  ██║ ██║   ██║ ████╗ ████║
█████╗   ██╔██╗ ██║ ██║   ██║ ██╔████╔██║
██╔══╝   ██║╚██╗██║ ██║   ██║ ██║╚██╔╝██║
███████╗ ██║ ╚████║ ╚██████╔╝ ██║ ╚═╝ ██║
╚══════╝ ╚═╝  ╚═══╝  ╚═════╝  ╚═╝     ╚═╝
  Drupal Enumeration Framework v3.0
        Crafted by @pistacha-git
```        
Professional Drupal reconnaissance and enumeration framework for authorized penetration testing.
## Description

`drupal-enum.sh` is a powerful Bash-based enumeration tool designed to perform deep reconnaissance on Drupal-based websites.
It integrates multiple discovery techniques to extract useful security information from a target installation, including:

- Drupal version identification

- Module enumeration (core, contrib & custom modules)

- Theme discovery

- Service and endpoint probing

- Sensitive file detection

- Directory listing analysis

- HTTP headers & configuration inspection

- This tool provides detailed, color‑coded output and supports optional report generation.

##🚀 Features
###Core Enumeration

- **Drupal Version Detection** 

- **CHANGELOG.txt extraction**

- **README.txt & VERSION file detection**

- **Generator meta‑tag parsing**

- **Module Enumeration**

- **Local module list database**

- **Pattern-based module discovery in HTML**

- **/sites/all/modules, /modules/contrib, /modules/custom directory probing**

- **Module signature matching**

- **Module version extraction when possible**

- **Theme Detection**

- **Active theme name extraction**

- **Header/CSS asset pattern analysis**

- **Enumeration of theme directories**

##🔐 Security Checks

- **Sensitive Files Testing**

- **Exposed configuration files**

- **Backup files**

- **Common Drupal debug files**

- **Directory Listing Detection**

- **Auto‑indexing in module & theme directories**

- **Listing traversal and module extraction**

- **Endpoint Enumeration**

- **/user/1 and user page probing**

- **/admin/ exposure checks**

- **/core/, /misc/, /sites/ directory mapping**

- **Security Headers & HTTPS Checks**

- **HSTS, CSP, X‑Frame‑Options, etc.**

- **HTTP → HTTPS redirection validation**

##🛠️ Requirements

###Dependencies

`bash` (5.0+)

`curl` — HTTP requests

`grep` — Pattern matching

`awk` — Text processing

`sed` — Stream editing

`jq` — Optional, for JSON parsing when endpoints return JSON

##💻 Installation

Clone the repository:
```bash
git clone https://github.com/pistacha-git/EnumX-Offensive-Enumeration-Tools.git
cd EnumX-Offensive-Enumeration-Tools
chmod +x drupal-enum.sh
```

##▶️ Usage
```bash
./drupal-enum.sh <target_url> [output_file]
```

⚠️ Legal Disclaimer

This tool is intended exclusively for:

Authorized penetration testing

Security research in controlled environments

Educational purposes

Unauthorized use against systems without explicit permission is illegal and unethical.

🧩 Author

Crafted by: @pistacha-git
GitHub: https://github.com/pistacha-git
