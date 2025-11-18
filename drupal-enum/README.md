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
        
A comprehensive **Drupal enumeration & security auditing tool** written in Bash.  
Esta herramienta permite un reconocimiento profundo de sitios Drupal, para propósitos de auditoría de seguridad.

---

## Features / Funcionalidades

- Detect Drupal core version (incluye Drupal 7, 8, 9 y 10)  
- Enumerate Drupal users (API REST, perfiles, comentarios, autocomplete…)  
- Detect installed modules and their versions  
- Enumerate themes (activos e inactivos)  
- Check for sensitive files (CHANGELOG, settings.php, backups, etc.)  
- Scan common Drupal endpoints (admin panel, cron.php, install.php…)  
- Detect JSON API / REST API exposure  
- Detect directory listing vulnerabilities  
- Scan for common misconfigurations (user enumeration, registration, error disclosure)  
- Analyze HTTP security headers (CSP, HSTS, X-Frame-Options…)  
- Check SSL/TLS configuration and mixed content  
- Detect known Drupal vulnerabilities (Drupalgeddon, CVEs, etc.)  
- Check admin access points  
- Validate safety of `sites/default/files/` directory (listing, PHP execution)  
- Generate a summary report with security recommendations

---

## ⚙️ Requirements / Requisitos

- Bash (tested on Linux / macOS)  
- `curl`  
- `grep`, `awk`, `sed`  
- Optional: `jq` (si está instalado, mejora el parseo de JSON)  

---

## 🚀 Usage / Uso

```bash
chmod +x drupal_enum.sh  
./drupal_enum.sh <target_url> [output_file]

