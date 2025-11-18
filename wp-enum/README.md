# WordPress Enumerator v3.0

Professional WordPress reconnaissance and enumeration framework for authorized penetration testing.

## Description

`wp-enum.sh` is a comprehensive Bash-based tool designed to perform in-depth enumeration of WordPress installations. It employs multiple techniques to gather intelligence about the target site, including version detection, user enumeration, plugin/theme discovery, and security misconfiguration identification.

## Features

### Core Enumeration
- **🔍 Version Detection** – Multiple methods (meta tags, readme.html, RSS feeds, asset versioning)
- **👥 User Enumeration** – REST API, Author ID iteration, RSS/Atom feeds, XML sitemaps
- **🔌 Plugin Discovery** – Homepage source analysis + common plugin probing
- **🎨 Theme Detection** – Active theme identification with version extraction
- **📊 Structured Output** – Color-coded terminal output + optional file logging

### Security Checks
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
