#!/bin/bash

# WordPress Enumeration Script - Professional Edition
# Crafted by @pistacha-git
# Built for precision reconnaissance within controlled and ethical offensive security environments.
# Version: 3.0 | https://github.com/pistacha-git

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[0;95m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_CYAN='\033[1;36m'
NC='\033[0m'

# Global variables
DETECTED_VERSION=""
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
declare -A USERS USER_IDS

banner() {
    echo -e "${BRIGHT_CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   ██╗    ██╗██████╗       ███████╗███╗   ██╗██╗   ██╗███╗   ███╗   ║
║   ██║    ██║██╔══██╗      ██╔════╝████╗  ██║██║   ██║████╗ ████║   ║
║   ██║ █╗ ██║██████╔╝█████╗█████╗  ██╔██╗ ██║██║   ██║██╔████╔██║   ║
║   ██║███╗██║██╔═══╝ ╚════╝██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║   ║
║   ╚███╔███╔╝██║           ███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║   ║
║    ╚══╝╚══╝ ╚═╝           ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝   ║
║                                                                    ║
║             WordPress Advanced Enumeration Tool v3.0               ║
║                    Crafted by @pistacha-git                        ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check for required dependencies
check_deps() {
    local missing=()
    for dep in curl grep awk sed; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    [ ${#missing[@]} -ne 0 ] && { echo -e "${RED}[!] Missing: ${missing[*]}${NC}"; exit 1; }
}

# Log function - outputs to console and optionally to file
log() { 
    echo -e "$1"
    [ -n "$OUTPUT" ] && echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT"
}

# Fetch URL content
fetch() { 
    curl -sL -A "$UA" -H "Accept: text/html" --max-time 8 --connect-timeout 4 "$1" 2>/dev/null
}

# Get HTTP status code
http_code() { 
    curl -so /dev/null -w "%{http_code}" -A "$UA" --max-time 3 "$1" 2>/dev/null
}

# Check if target is running WordPress
check_wordpress() {
    log "${BRIGHT_BLUE}[*] Checking WordPress...${NC}"
    local page=$(fetch "$TARGET")
    local score=0
    
    echo "$page" | grep -iq "wp-content" && ((score++))
    echo "$page" | grep -iq "wp-includes" && ((score++))
    [ "$(http_code "$TARGET/wp-login.php")" = "200" ] && ((score++))
    
    [ $score -ge 2 ] && { log "${GREEN}[+] WordPress detected ($score/3 indicators)${NC}\n"; return 0; }
    log "${RED}[!] Not WordPress ($score/3 indicators)${NC}"; return 1
}

# Detect WordPress version using multiple methods
detect_version() {
    log "${BRIGHT_BLUE}[*] Detecting version...${NC}"
    local page=$(fetch "$TARGET")
    
    # Method 1: Meta generator tag
    local ver=$(echo "$page" | grep -i "generator" | grep -oP 'WordPress[/ ]+\K[0-9.]+' | head -1)
    [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (meta): $ver${NC}"; }
    
    # Method 2: readme.html file
    if [ -z "$ver" ]; then
        ver=$(fetch "$TARGET/readme.html" | grep -oP 'Version \K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (readme): $ver${NC}"; }
    fi
    
    # Method 3: RSS feed
    if [ -z "$ver" ]; then
        ver=$(fetch "$TARGET/feed/" | grep -oP '<generator>.*WordPress[/ ]+\K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (RSS): $ver${NC}"; }
    fi
    
    # Method 4: CSS/JS assets version parameter
    if [ -z "$ver" ]; then
        ver=$(echo "$page" | grep -oP 'wp-includes/[^"]*ver=\K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (assets): $ver${NC}"; }
    fi
    
    [ -z "$DETECTED_VERSION" ] && log "${YELLOW}[!] Version hidden${NC}"
    echo ""
}

# User enumeration using multiple techniques
enumerate_users() {
    log "${BRIGHT_BLUE}[*] Enumerating users...${NC}"
    log "${CYAN}[i] Techniques: REST API, Author ID, RSS, Sitemap${NC}"
    local found=0
    
    # Method 1: REST API (most reliable)
    log "${CYAN}[1/4] REST API${NC}"
    local api=$(fetch "$TARGET/wp-json/wp/v2/users?per_page=100")
    
    if command -v jq &>/dev/null && echo "$api" | jq -e . >/dev/null 2>&1; then
        # With jq (proper JSON parsing)
        while IFS= read -r line; do
            local id=$(echo "$line" | jq -r '.id')
            local name=$(echo "$line" | jq -r '.name')
            local slug=$(echo "$line" | jq -r '.slug')
            [ "$id" != "null" ] && [ -n "$slug" ] && {
                USERS["$slug"]="$name"
                USER_IDS["$slug"]="$id"
                log "${GREEN}    [+] ID=$id | $name ($slug)${NC}"
                ((found++))
            }
        done < <(echo "$api" | jq -c '.[]' 2>/dev/null)
    else
        # Without jq (regex fallback)
        while IFS= read -r obj; do
            local id=$(echo "$obj" | grep -oP '"id":\K[0-9]+')
            local slug=$(echo "$obj" | grep -oP '"slug":"\K[^"]+')
            local name=$(echo "$obj" | grep -oP '"name":"\K[^"]+')
            [ -n "$id" ] && [ -n "$slug" ] && {
                USERS["$slug"]="$name"
                USER_IDS["$slug"]="$id"
                log "${GREEN}    [+] ID=$id | $name ($slug)${NC}"
                ((found++))
            }
        done < <(echo "$api" | grep -oP '\{"id":[0-9]+[^}]+\}')
    fi
    [ $found -eq 0 ] && log "${YELLOW}    [-] REST API blocked${NC}"
    
    # Method 2: Author ID enumeration
    log "${CYAN}[2/4] Enumeration /?author=N${NC}"
    local test=$(curl -sI -L -A "$UA" --max-time 2 "$TARGET/?author=1" 2>/dev/null | grep -i "location:")
    
    if [ -n "$test" ]; then
        local auth_found=0
        for i in {1..30}; do
            [ $((i % 10)) -eq 0 ] && echo -ne "${BRIGHT_BLUE}    Testing ID $i/30...\r${NC}"
            
            local redir=$(curl -sI -L -A "$UA" --max-time 1.5 "$TARGET/?author=$i" 2>/dev/null | 
                         grep -i "location:" | grep -oP 'author/\K[^/\r\n]+')
            
            [ -n "$redir" ] && [ -z "${USERS[$redir]}" ] && {
                USERS["$redir"]="$redir"
                USER_IDS["$redir"]="$i"
                echo -ne "\033[2K"
                log "${GREEN}    [+] ID=$i | $redir${NC}"
                ((found++)); ((auth_found++))
            }
        done
        echo -ne "\033[2K\r"
        [ $auth_found -eq 0 ] && log "${YELLOW}    [-] No new users found${NC}"
    else
        log "${YELLOW}    [-] Enumeration blocked${NC}"
    fi
    
    # Method 3: RSS/Atom feeds
    log "${CYAN}[3/4] RSS/Atom feeds${NC}"
    local feed_found=0
    for feed in "feed/" "feed/atom/"; do
        local authors=$(fetch "$TARGET/$feed" | grep -oP '<dc:creator><!\[CDATA\[\K[^\]]+' | sort -u)
        while IFS= read -r author; do
            [ -n "$author" ] && [ -z "${USERS[$author]}" ] && {
                USERS["$author"]="$author"
                log "${GREEN}    [+] $author (RSS)${NC}"
                ((found++)); ((feed_found++))
            }
        done <<< "$authors"
    done
    [ $feed_found -eq 0 ] && log "${YELLOW}    [-] No authors in feeds${NC}"
    
    # Method 4: XML Sitemap
    log "${CYAN}[4/4] XML Sitemap${NC}"
    local sitemap=$(fetch "$TARGET/wp-sitemap-users-1.xml")
    local sit_found=0
    if echo "$sitemap" | grep -q "<url>"; then
        while IFS= read -r user; do
            [ -n "$user" ] && [ -z "${USERS[$user]}" ] && {
                USERS["$user"]="$user"
                log "${GREEN}    [+] $user (sitemap)${NC}"
                ((found++)); ((sit_found++))
            }
        done < <(echo "$sitemap" | grep -oP 'author/\K[^/<]+' | sort -u)
    fi
    [ $sit_found -eq 0 ] && log "${YELLOW}    [-] No user sitemap${NC}"
    
    # Results summary
    echo ""
    if [ $found -gt 0 ]; then
        log "${GREEN}╔═══════════════════════════════════════╗${NC}"
        log "${GREEN}║  USERS FOUND: $found                       ${NC}"
        log "${GREEN}╚═══════════════════════════════════════╝${NC}"
        log "${CYAN}┌─────┬────────────────────┬──────────────────────┐${NC}"
        log "${CYAN}│ ID  │ Username           │ Display Name         │${NC}"
        log "${CYAN}├─────┼────────────────────┼──────────────────────┤${NC}"
        for slug in "${!USERS[@]}"; do
            printf "${CYAN}│${NC} %-3s ${CYAN}│${NC} %-18s ${CYAN}│${NC} %-20s ${CYAN}│${NC}\n" \
                "${USER_IDS[$slug]:-?}" "${slug:0:18}" "${USERS[$slug]:0:20}"
        done | sort
        log "${CYAN}└─────┴────────────────────┴──────────────────────┘${NC}"
        
        # Save users to separate file if output enabled
        [ -n "$OUTPUT" ] && {
            local ufile="${OUTPUT%.txt}_users.txt"
            printf "%s\n" "${!USERS[@]}" > "$ufile"
            log "${GREEN}[✓] Users saved: $ufile${NC}"
        }
         
        log "\n${YELLOW}[!] WARNING:${NC}"
        log "${YELLOW}    → $found users enumerated${NC}"
        log "${YELLOW}    → Vulnerable to brute force attacks${NC}"
        log "${CYAN}[i] Recommendations:${NC}"
        log "${CYAN}    • Disable REST API user endpoints${NC}"
        log "${CYAN}    • Block /?author=N enumeration${NC}"
        log "${CYAN}    • Enable 2FA${NC}"
    else
        log "${RED}[!] Could not enumerate users${NC}"
        log "${GREEN}[+] Enumeration is protected${NC}"
    fi
    echo ""
}

# Plugin enumeration
enumerate_plugins() {
    log "${BRIGHT_BLUE}[*] Enumerating plugins...${NC}"
    local page=$(fetch "$TARGET")
    local found=0
    declare -A plugins
    
    # Extract plugins from homepage source
    while IFS= read -r plugin; do
        [ -z "${plugins[$plugin]}" ] && {
            plugins[$plugin]=1
            local ver=$(fetch "$TARGET/wp-content/plugins/$plugin/readme.txt" | 
                       grep -iP 'Stable tag: \K[0-9.]+' | head -1)
            [ -n "$ver" ] && log "${GREEN}    [+] $plugin (v$ver)${NC}" || log "${GREEN}    [+] $plugin${NC}"
            ((found++))
        }
    done < <(echo "$page" | grep -oP 'wp-content/plugins/\K[^/"\?]+' | sort -u)
    
    # Check for common/popular plugins
    local common=("akismet" "contact-form-7" "elementor" "jetpack" "wordpress-seo" 
                  "woocommerce" "wordfence" "classic-editor" "wpforms-lite" "duplicate-post")
    for plugin in "${common[@]}"; do
        [ -z "${plugins[$plugin]}" ] && [ "$(http_code "$TARGET/wp-content/plugins/$plugin/readme.txt")" = "200" ] && {
            plugins[$plugin]=1
            log "${GREEN}    [+] $plugin (common)${NC}"
            ((found++))
        }
    done
    
    [ $found -eq 0 ] && log "${YELLOW}[!] No plugins found${NC}" || log "${GREEN}[✓] Plugins found: $found${NC}"
    echo ""
}

# Theme enumeration
enumerate_themes() {
    log "${BRIGHT_BLUE}[*] Enumerating themes...${NC}"
    local page=$(fetch "$TARGET")
    local theme=$(echo "$page" | grep -oP 'wp-content/themes/\K[^/"\?]+' | head -1)
    
    if [ -n "$theme" ]; then
        local css=$(fetch "$TARGET/wp-content/themes/$theme/style.css")
        local ver=$(echo "$css" | grep -iP 'Version:\s*\K[0-9.]+' | head -1)
        local name=$(echo "$css" | grep -iP 'Theme Name:\s*\K[^*\n]+' | head -1 | xargs)
        log "${GREEN}    [+] Active theme: $theme${NC}"
        [ -n "$name" ] && log "${GREEN}        Name: $name${NC}"
        [ -n "$ver" ] && log "${GREEN}        Version: $ver${NC}"
    else
        log "${YELLOW}[!] Theme not detected${NC}"
    fi
    echo ""
}

# XML-RPC vulnerability check
check_xmlrpc() {
    log "${BRIGHT_BLUE}[*] Checking XML-RPC...${NC}"
    local resp=$(curl -sX POST -A "$UA" -H "Content-Type: text/xml" \
        -d '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName></methodCall>' \
        "$TARGET/xmlrpc.php" 2>/dev/null)
    
    if echo "$resp" | grep -q "methodResponse"; then
        log "${RED}    [!] XML-RPC ENABLED - Security risk${NC}"
        log "${YELLOW}        Risks: Brute force, DDoS, pingback abuse${NC}"
    else
        log "${GREEN}    [+] XML-RPC disabled or restricted${NC}"
    fi
    echo ""
}

# Check for sensitive/exposed files
check_sensitive_files() {
    log "${BRIGHT_BLUE}[*] Checking sensitive files...${NC}"
    local exposed=0
    local files=(
        "wp-config.php:CRITICAL" "wp-config.php.bak:CRITICAL" 
        ".env:CRITICAL" "backup.sql:CRITICAL" "database.sql:CRITICAL"
        "backup.zip:HIGH" "debug.log:MEDIUM" "wp-content/debug.log:MEDIUM"
        ".git/config:HIGH" "readme.html:INFO"
    )
    
    for entry in "${files[@]}"; do
        IFS=':' read -r file sev <<< "$entry"
        [ "$(http_code "$TARGET/$file")" = "200" ] && {
            case $sev in
                CRITICAL) log "${RED}    [!!!] $sev: $file${NC}" ;;
                HIGH) log "${RED}    [!!] $sev: $file${NC}" ;;
                MEDIUM) log "${YELLOW}    [!] $sev: $file${NC}" ;;
                *) log "${CYAN}    [i] $sev: $file${NC}" ;;
            esac
            ((exposed++))
        }
    done
    
    [ $exposed -eq 0 ] && log "${GREEN}    [+] No sensitive files exposed${NC}" || 
        log "${YELLOW}    [!] Exposed files: $exposed${NC}"
    echo ""
}

# Check for directory listing vulnerabilities
check_dirs() {
    log "${BRIGHT_BLUE}[*] Checking directory listing...${NC}"
    local exposed=0
    for dir in "wp-content/uploads/" "wp-content/plugins/" "wp-content/themes/"; do
        fetch "$TARGET/$dir" | grep -qi "Index of" && {
            log "${RED}    [!] Listing enabled: $dir${NC}"
            ((exposed++))
        }
    done
    [ $exposed -eq 0 ] && log "${GREEN}    [+] Directory listing disabled${NC}"
    echo ""
}

# Check admin login page accessibility
check_login() {
    log "${BRIGHT_BLUE}[*] Checking admin access...${NC}"
    local code=$(http_code "$TARGET/wp-login.php")
    [ "$code" = "200" ] && log "${GREEN}    [+] Login: $TARGET/wp-login.php${NC}" ||
        log "${YELLOW}    [-] Login HTTP $code${NC}"
    echo ""
}

# Check security headers
check_headers() {
    log "${BRIGHT_BLUE}[*] Checking security headers...${NC}"
    local headers=$(curl -sI -A "$UA" "$TARGET" 2>/dev/null)
    
    echo "$headers" | grep -qi "X-Frame-Options" && 
        log "${GREEN}    [+] X-Frame-Options${NC}" || 
        log "${YELLOW}    [-] X-Frame-Options (clickjacking risk)${NC}"
    
    echo "$headers" | grep -qi "Strict-Transport-Security" && 
        log "${GREEN}    [+] HSTS${NC}" || 
        log "${YELLOW}    [-] HSTS (recommended for HTTPS)${NC}"
    
    echo "$headers" | grep -qi "X-Powered-By" && {
        local pw=$(echo "$headers" | grep -i "X-Powered-By" | cut -d: -f2 | xargs)
        log "${YELLOW}    [-] X-Powered-By exposed: $pw${NC}"
    } || log "${GREEN}    [+] X-Powered-By hidden${NC}"
    
    echo ""
}

# SSL/TLS configuration check
check_ssl() {
    log "${BRIGHT_BLUE}[*] Checking SSL/TLS...${NC}"
    if [[ "$TARGET" =~ ^https:// ]]; then
        log "${GREEN}    [+] Site uses HTTPS${NC}"
        local http="${TARGET/https:/http:}"
        curl -sI -L -A "$UA" "$http" 2>/dev/null | grep -qi "location.*https" && 
            log "${GREEN}    [+] HTTP redirects to HTTPS${NC}" || 
            log "${YELLOW}    [!] HTTP does NOT redirect to HTTPS${NC}"
    else
        log "${RED}    [!] Site uses HTTP (unencrypted)${NC}"
    fi
    echo ""
}

# Quick vulnerability/misconfiguration scan
scan_vulns() {
    log "${BRIGHT_BLUE}[*] Scanning misconfigurations...${NC}"
    
    # User enumeration vulnerability
    curl -sI -L -A "$UA" "$TARGET/?author=1" 2>/dev/null | grep -qi "author/" && 
        log "${RED}    [!] User enumeration possible (/?author=N)${NC}" || 
        log "${GREEN}    [+] /?author=N enumeration blocked${NC}"
    
    # REST API user disclosure
    fetch "$TARGET/wp-json/wp/v2/users" | grep -q '"id"' && 
        log "${RED}    [!] REST API exposes users${NC}" || 
        log "${GREEN}    [+] REST API users protected${NC}"
    
    # Debug log exposure
    [ "$(http_code "$TARGET/wp-content/debug.log")" = "200" ] && 
        log "${RED}    [!] debug.log PUBLIC${NC}"
    
    echo ""
}

# Generate final summary report
generate_summary() {
    log "${BRIGHT_CYAN}═══════════════════════════════════════════${NC}"
    log "${BRIGHT_CYAN}         ENUMERATION SUMMARY${NC}"
    log "${BRIGHT_CYAN}═══════════════════════════════════════════${NC}"
    log "${CYAN}Target:${NC} $TARGET"
    log "${CYAN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    log "${CYAN}WP Version:${NC} ${DETECTED_VERSION:-Unknown}"
    log "${CYAN}Users:${NC} ${#USERS[@]}"
    
    [ -n "$OUTPUT" ] && log "\n${GREEN}[✓] Report saved: $OUTPUT${NC}"
    
    log "\n${CYAN}Next steps:${NC}"
    log "${CYAN}  1. Full WPScan:${NC} ${YELLOW}wpscan --url $TARGET -e ap,at,u${NC}"
    log "${CYAN}  2. Review plugins/themes vs CVE${NC}"
    log "${CYAN}  3. Configuration analysis${NC}"
    
    log "\n${BRIGHT_CYAN}═══════════════════════════════════════════${NC}"
    log "${RED}⚠  Authorized testing only${NC}"
    log "${BRIGHT_CYAN}   github.com/pistacha-git | @pistacha-git${NC}"
    log "${BRIGHT_CYAN}═══════════════════════════════════════════${NC}"
}

# Main execution function
main() {
    banner
    
    # Usage instructions if no arguments provided
    [ $# -lt 1 ] && {
        echo -e "${RED}Usage: $0 <target_url> [output_file]${NC}"
        echo -e "\n${YELLOW}Examples:${NC}"
        echo -e "  $0 http://example.com"
        echo -e "  $0 https://wordpress.site report.txt"
        echo -e "\n${CYAN}Engineered by @pistacha-git${NC}"
        echo -e "${CYAN}GitHub: github.com/pistacha-git${NC}"
        exit 1
    }
    
    TARGET="${1%/}"
    OUTPUT="$2"
    
    # Validate URL format
    [[ ! "$TARGET" =~ ^https?:// ]] && {
        echo -e "${RED}[!] Invalid URL. Use http:// or https://${NC}"
        exit 1
    }
    
    check_deps
    
    # Create output file if specified
    [ -n "$OUTPUT" ] && {
        cat > "$OUTPUT" << EOF
╔══════════════════════════════════════════════════════════╗
║          WordPress Security Enumeration Report          ║
╚══════════════════════════════════════════════════════════╝

Target: $TARGET
Date: $(date '+%Y-%m-%d %H:%M:%S')
Analyst: @pistacha-git
Tool: WP-Enumerator v3.0 Professional Edition

═══════════════════════════════════════════════════════════

EOF
        log "${GREEN}[+] Output saving to: $OUTPUT${NC}\n"
    }
    
    log "${GREEN}[+] Starting enumeration: $TARGET${NC}\n"
    
    # Execute enumeration modules
    check_wordpress || exit 1
    detect_version
    enumerate_users
    enumerate_plugins
    enumerate_themes
    check_xmlrpc
    check_sensitive_files
    check_dirs
    check_login
    check_headers
    check_ssl
    scan_vulns
    generate_summary
    
    log "\n${GREEN}[✓] Enumeration completed${NC}\n"
}

# Trap keyboard interrupts
trap 'echo -e "\n${RED}[!] Interrupted${NC}"; exit 1' INT TERM
main "$@"
