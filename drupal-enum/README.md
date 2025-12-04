```text
██████═╗ ██████╗  ██╗   ██╗ ██████╗  █████╗   ██╗           ███████╗ ███╗   ██╗ ██╗   ██╗ ███╗   ███╗
██   ██║ ██╔══██╗ ██║   ██║ ██╔══██╗ ██╔══██╗ ██║           ██╔════╝ ████╗  ██║ ██║   ██║ ████╗ ████║
██   ██║ ██████╔╝ ██║   ██║ ██████╔╝ ███████║ ██║           █████╗   ██╔██╗ ██║ ██║   ██║ ██╔████╔██║
██   ██║ ██╔══██╗ ██║   ██║ ██╔═══╝  ██╔══██║ ██║           ██╔══╝   ██║╚██╗██║ ██║   ██║ ██║╚██╔╝██║
██████╔╝ ██║  ██║ ╚██████╔╝ ██║      ██║  ██║ ███████╗      ███████╗ ██║ ╚████║ ╚██████╔╝ ██║ ╚═╝ ██║
╚═════╝  ╚═╝  ╚═╝  ╚═════╝  ╚═╝      ╚═╝  ╚═╝ ╚══════╝      ╚══════╝ ╚═╝  ╚═══╝  ╚═════╝  ╚═╝     ╚═╝

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

## 🚀 Features
### Core Enumeration

- **Drupal Version Detection** – Identifies the version of the target Drupal installation using multiple discovery techniques.

- **CHANGELOG.txt Extraction** – Attempts to retrieve the core CHANGELOG.txt, often exposing the exact Drupal version.

- **README.txt & VERSION File Detection** – Probes for common documentation files frequently left publicly accessible.

- **Generator Meta‑Tag Parsing** – Examines the HTML <meta name="Generator"> tag, which may disclose the Drupal version.

- **Module Enumeration** – Comprehensive detection of installed modules through different enumeration strategies.

- **Local Module List Database** – Matches known Drupal module names from a local signature database.

- **Pattern‑Based Module Discovery in HTML** – Extracts module names by scanning page source for /modules/ references.

- **Directory Probing (/sites/all/modules, /modules/contrib, /modules/custom)** – Searches classical Drupal module locations and detects directory listing.

- **Module Signature Matching** – Uses keyword detection to confirm module names found in HTML or directory listings.

- **Module Version Extraction** – Retrieves module version numbers from accessible .info or .yml files when available.

- **Theme Detection** – Identifies the active theme and enumerates themes present on the system.

- **Active Theme Name Extraction** – Detects the main theme used by the target site.

- **Header/CSS Asset Pattern Analysis** – Infers theme names from CSS/JS file paths in page headers.

- **Theme Directory Enumeration** – Probes theme directories for listing and accessible metadata.
  

## 🔐 Security Checks

- **Sensitive Files Testing** – Locates exposed or misconfigured files that may leak sensitive information.

- **Exposed Configuration Files** – Checks for settings.php, backups, or exported configs visible to the public.

- **Backup Files** – Attempts to identify backup archives or old configuration snapshots.

- **Common Drupal Debug Files** – Searches for debug logs or leftover development artifacts.

- **Directory Listing Detection** – Determines whether directory indexing is enabled on critical Drupal paths.

- **Auto‑Indexing in Module & Theme Directories** – Detects open listings that expose installed modules/themes.

- **Listing Traversal and Module Extraction** – Extracts module names directly from accessible file listings.

- **Endpoint Enumeration** – Maps typical Drupal routes to detect exposure or misconfiguration.

- **/user/1 and User Page Probing** – Checks whether user profiles are publicly accessible.

- **/admin/ Exposure Checks** – Identifies whether admin paths leak information or are improperly protected.

- **/core/, /misc/, /sites/ Directory Mapping** – Examines core Drupal directories for public accessibility.

- **Security Headers & HTTPS Checks** – Performs a basic security assessment on HTTP responses.

- **HSTS, CSP, X‑Frame‑Options, etc.** – Identifies missing or weak security headers.

- **HTTP → HTTPS Redirection Validation** – Verifies secure redirection and proper TLS usage.

## 🛠️ Requirements

### Dependencies

`bash` (5.0+)

`curl` — HTTP requests

`grep` — Pattern matching

`awk` — Text processing

`sed` — Stream editing

`jq` — Optional, for JSON parsing when endpoints return JSON

## 💻 Installation

Clone the repository:
```bash
git clone https://github.com/pistacha-git/EnumX-Offensive-Enumeration-Tools.git
cd EnumX-Offensive-Enumeration-Tools/drupal-enum
chmod +x drupal-enum.sh
```

## ▶️ Usage
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

<div align="center">
  <img width="500" height="500" alt="PistachaHacker" src="https://github.com/user-attachments/assets/d3242a6a-a0e3-4641-a46c-0fbb2f2873e2" />
</div>


<img width="1162" height="596" alt="image" src="https://github.com/user-attachments/assets/b9c421c5-cb0b-45dd-8345-039072c541f7" />


