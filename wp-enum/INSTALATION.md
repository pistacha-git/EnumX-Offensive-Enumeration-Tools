### Installation

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt update
sudo apt install curl grep gawk sed jq

# Install dependencies (RHEL/CentOS)
sudo yum install curl grep gawk sed jq

# Install dependencies (macOS)
brew install curl grep gawk gnu-sed jq
```

## 🚀 Quick Start

```bash
# Make script executable
chmod +x wp-enum.sh

# Basic enumeration
./wp-enum.sh https://example.com

# With report generation
./wp-enum.sh https://example.com report.txt
```

## 🔍 Enumeration Techniques

### 1. WordPress Detection
- Searches for `wp-content` and `wp-includes` in HTML
- Probes `wp-login.php` accessibility
- Requires 2/3 indicators for positive detection

### 2. Version Detection Priority
1. **Meta generator tag** – `<meta name="generator" content="WordPress X.X.X">`
2. **readme.html** – Official version documentation file
3. **RSS feed** – Generator field in feed XML
4. **Asset versioning** – Query parameters in CSS/JS includes

### 3. User Enumeration Methods
1. **REST API** (`/wp-json/wp/v2/users`) – Most reliable, often enabled by default
2. **Author ID enumeration** (`/?author=N`) – Tests IDs 1-30, follows redirects
3. **RSS/Atom feeds** – Extracts `<dc:creator>` tags
4. **XML Sitemap** – Parses `/wp-sitemap-users-1.xml`

### 4. Plugin/Theme Discovery
- Parses homepage source for `/wp-content/plugins/` and `/wp-content/themes/`
- Probes `readme.txt` for version information
- Tests common plugins: Akismet, Contact Form 7, Elementor, Jetpack, WooCommerce, etc.

## ⚠️ Security Considerations

### Detected Vulnerabilities
The tool identifies:
- **User enumeration** – REST API exposure, author ID leakage
- **XML-RPC enabled** – Brute force amplification, DDoS pingback attacks
- **Sensitive file exposure** – Config files, backups, database dumps, .git directories
- **Directory listing** – Browsable uploads/plugins/themes folders
- **Missing security headers** – Clickjacking, protocol downgrade risks
- **HTTP usage** – Unencrypted traffic

### Ethical Usage
- ✅ **DO**: Use only on systems you own or have written authorization to test
- ✅ **DO**: Respect rate limits and avoid service disruption
- ✅ **DO**: Document findings professionally for remediation
- ❌ **DON'T**: Use against unauthorized targets
- ❌ **DON'T**: Perform brute force attacks without explicit permission
- ❌ **DON'T**: Share credentials or sensitive data found during testing


## 📧 Author

**@pistacha-git**  
GitHub: [github.com/pistacha-git](https://github.com/pistacha-git)

---

*Built for professional penetration testers and security researchers.*  
*Use responsibly. Test ethically.*
