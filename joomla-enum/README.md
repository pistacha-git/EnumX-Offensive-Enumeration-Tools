```text
     ██╗ ██████╗  ██████╗ ███╗   ███╗██╗      █████╗     ███████╗███╗   ██╗██╗   ██╗███╗   ███╗
     ██║██╔═══██╗██╔═══██╗████╗ ████║██║     ██╔══██╗    ██╔════╝████╗  ██║██║   ██║████╗ ████║
     ██║██║   ██║██║   ██║██╔████╔██║██║     ███████║    █████╗  ██╔██╗ ██║██║   ██║██╔████╔██║
██   ██║██║   ██║██║   ██║██║╚██╔╝██║██║     ██╔══██║    ██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║
╚█████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██║    ███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║
 ╚════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝

                        Joomla Advanced Enumeration Tool v3.0
                              Crafted by @pistacha-git

```                             
Professional Joomla reconnaissance and enumeration framework for authorized penetration testing.
## Description
`joomla-enum.sh` is a powerful Bash-based enumeration tool designed to perform comprehensive reconnaissance on Joomla-based websites. 
It integrates multiple discovery techniques to extract critical security information from target installations, including:

- Joomla version identification
  
- User enumeration (multiple techniques)
  
- Extension discovery (components, modules, plugins)
  
- Template detection
  
- Sensitive file exposure
  
- Configuration disclosure analysis
  
- Security header inspection
  
- SSL/TLS configuration review

- This tool provides detailed, color-coded output and supports optional report generation for documentation purposes.

## 🚀 Features
### Core Enumeration
- **Joomla Detection & Version Identification**

- **Multi-indicator Joomla fingerprinting (4 detection methods)**

- **Version extraction from joomla.xml manifest files**

- **Language XML file version parsing**

- **Meta generator tag analysis**

- **README.txt file inspection**

- **Asset versioning pattern matching**

### User Enumeration

- **Login error-based user discovery**
  
- **Author page enumeration (articles scanning)**
  
- **RSS/Atom feed author extraction**
  
- **Contact component profile discovery**
  
- **Comprehensive username database with source tracking**
  
- **Automatic user list export**

### Extension Discovery

- **Component detection from HTML source**
  
- **Common vulnerable component checking**

- **Module enumeration (mod_*)**
  
- **Plugin discovery across multiple types (system, content, user, authentication, editors)**
  
- **Version information extraction from manifest files**
  
- **Extension count summary**

### Template Detection

- **Active template identification**
  
- **Template version and metadata extraction**
  
- **Template author information**
  
- **templateDetails.xml parsing**


## 🔐 Security Checks
🔐 Security Checks

- **Sensitive Files Testing** – Locates exposed or misconfigured files that may leak critical information from Joomla installations.

- **Configuration File Exposure** – Checks for configuration.php, backup copies, and exported configurations visible to the public.

- **Database Credential Leakage** – Detects readable configuration files that may expose database usernames, passwords, and connection strings.

- **JConfig Class Detection** – Identifies exposed PHP configuration classes that contain sensitive site settings.

- **Backup Archive Discovery** – Attempts to identify backup files including .zip, .tar.gz, .bak, and SQL dumps left in accessible directories.

- **Environment File Scanning** – Searches for .env files and other environment configuration files that may contain API keys or credentials.

- **Common Joomla Debug Files** – Locates debug logs, error logs, and leftover development artifacts in /logs/ and /administrator/logs/.

- **Version Control Exposure** – Checks for exposed .git/config, .svn/entries, and other repository metadata that shouldn't be public.

- **phpinfo() Detection** – Identifies test files like phpinfo.php or info.php that expose server configuration details.

- **Directory Listing Detection** – Determines whether directory indexing is enabled on critical Joomla paths.

- **Auto-Indexing in Extension Directories** – Detects open listings in /components/, /modules/, /plugins/, and /templates/ that expose installed extensions.

- **Media & Upload Directory Exposure** – Checks whether /images/, /media/, /tmp/, and /cache/ directories allow public browsing.

- **Administrator Directory Indexing** – Verifies if the /administrator/ backend directory tree is exposed through directory listing.

- **Endpoint Enumeration** – Maps typical Joomla routes and components to detect exposure or misconfiguration.
  
- *User Profile Accessibility** – Probes /index.php?option=com_users&view=user&id=N to check if user profiles are publicly accessible.
  
- **Admin Panel Exposure Checks** – Identifies whether /administrator/, /admin/, and backend paths leak information or are improperly protected.
  
- **/installation/ Directory Presence** – Detects if the installation directory still exists post-deployment, which is a critical security risk.
  
- **Test & Development Installation Discovery** – Searches for /test/, /dev/, /demo/, /backup/, and /old/ directories that may contain vulnerable copies.
  
- **Core Directory Mapping** – Examines Joomla core directories like /libraries/, /includes/, and /bin/ for public accessibility.
  
- **Component & Module Path Analysis** – Tests accessibility of individual component and module directories to identify information disclosure.
  
- **Security Headers & HTTPS Checks** – Performs comprehensive security assessment on HTTP response headers.
  
- **X-Frame-Options Validation** – Checks for clickjacking protection headers to prevent iframe embedding attacks.
  
- **Content-Security-Policy (CSP) Analysis** – Identifies presence and configuration of CSP headers to mitigate XSS attacks.
  
- **Strict-Transport-Security (HSTS)** – Verifies HSTS header implementation to enforce HTTPS connections.
  
- **X-Content-Type-Options Verification** – Checks for MIME-sniffing protection to prevent content type attacks.
  
- **X-Powered-By Header Disclosure** – Detects information leakage through server technology headers.
  
- **Server Banner Inspection** – Examines server identification headers that may reveal version information
  
- **SSL/TLS Configuration Assessment** – Validates proper encryption implementation and certificate usage.
  
- **HTTPS Usage Verification** – Confirms whether the site operates over encrypted connections.
  
- **HTTP → HTTPS Redirection Testing** – Validates automatic secure redirection from unencrypted requests.
  
- **Mixed Content Detection** – Identifies potential mixed content issues that could compromise HTTPS security.
  
- **Unencrypted Connection Warnings** – Alerts when credentials or sensitive data may be transmitted in cleartext.
  
- **Misconfiguration Scanning** – Identifies common Joomla security misconfigurations and weak settings.
  
- **User Registration Status Detection** – Checks if public user registration is enabled via com_users component.
  
- **Debug Mode Identification** – Detects JDEBUG flags and debug mode activation that may expose sensitive system information.
  
- **Cache Directory Exposure** – Verifies if /cache/ directory is publicly accessible or allows listing.
  
- **Temporary File Access** – Checks whether /tmp/ directory exposes temporary files or session data.
  
- **Error Reporting Configuration** – Attempts to identify verbose error messages that reveal system paths or configurations.
  
- **Information Disclosure Files** – Analyzes publicly accessible documentation and metadata files.
  
- **robots.txt Enumeration** – Parses robots.txt for disallowed paths that may reveal hidden or sensitive areas.
  
- **Disallow Directive Analysis** – Counts and examines restricted paths that could indicate protected content locations.
  
- **security.txt Discovery** – Checks for /.well-known/security.txt indicating responsible disclosure policies.
  
- **humans.txt Detection** – Identifies humans.txt files that may contain team information or technology stack details.
  
- **README & LICENSE Files** – Locates README.txt, LICENSE.txt, and CHANGELOG.txt that may disclose version information.


## 🛠 Requirements

### Dependencies

`bash` (4.0+)

`curl` — HTTP requests and header inspection

`grep` — Pattern matching and content extraction

`awk` — Text processing

`sed` — Stream editing and output formatting


All dependencies are typically pre-installed on most Linux distributions.

## 💻 Installation
Clone the repository:
```bash
git clone https://github.com/pistacha-git/EnumX-Offensive-Enumeration-Tools.git
cd EnumX-Offensive-Enumeration-Tools/joomla-enum
chmod +x joomla-enum.sh
```

## ▶️ Usage
```bash
./joomla-enum.sh <target_url>
```
Scan with Report Generation
```bash
./joomla-enum.sh <target_url> output_report.txt
```

### Output Files
When an output file is specified, the tool generates:
- **Main report**: Complete enumeration results with formatting
- **User list**: Separate file with discovered usernames (`*_users.txt`)

---

## 📊 Sample Output
```bash
╔═══════════════════════════════════════════════════════════╗
║         Joomla Advanced Enumeration Tool v3.0             ║
║               Crafted by @pistacha-git                    ║
╚═══════════════════════════════════════════════════════════╝

[*] Checking Joomla...
[+] Joomla detected (4/4 indicators)

[*] Detecting Joomla version...
[+] Version (manifest): 4.2.7

[*] Enumerating users...
[i] Techniques: Login error, Author pages, RSS, Contact forms
    [+] User exists: admin
    [+] Author: John Doe (article 3)

╔═══════════════════════════════════════════╗
║  USERS FOUND: 2                           ║
╚═══════════════════════════════════════════╝

[*] Checking sensitive files...
    [!!!] CRITICAL: configuration.php [HTTP 200]
    [!] MEDIUM: htaccess.txt [HTTP 200]

═══════════════════════════════════════════
         ENUMERATION SUMMARY
═══════════════════════════════════════════
Target: https://example.com
Joomla Version: 4.2.7
Users Found: 2
Extensions Found: 12

🎯 Key Features Highlight

4 User Enumeration Techniques: Login errors, author pages, RSS feeds, contact profiles
5 Version Detection Methods: Manifest, language files, meta tags, README, assets
Multiple Extension Types: Components, modules, plugins with version extraction
Severity-Based File Classification: CRITICAL, HIGH, MEDIUM, INFO levels
Comprehensive Security Assessment: Headers, SSL, configurations, misconfigurations
Professional Reporting: Formatted output with color coding and structured tables
Automatic User Export: Separate username list generation for further testing
Actionable Recommendations: Security improvement suggestions included
```

⚠️ Legal Disclaimer

This tool is intended exclusively for:

 Authorized penetration testing
 
 Security research in controlled environments
 
 Educational purposes
 
Unauthorized use against systems without explicit written permission is illegal and unethical.

The author assumes no liability for misuse or damage caused by this tool. Always obtain proper authorization before conducting security assessments.

<div align="center">
  <img width="940" height="888" alt="image" src="https://github.com/user-attachments/assets/d09aed89-8b7d-4644-8f30-9c50a6c9053a" />
</div>

🧩 Author

Crafted by: @pistacha-git

GitHub: https://github.com/pistacha-git

<div align="center">
  <img width="500" height="500" alt="PistachaHacker" src="https://github.com/user-attachments/assets/d3242a6a-a0e3-4641-a46c-0fbb2f2873e2" />
</div>



