#!/bin/bash

# WordPress Enumeration Script - Professional Edition
# Crafted by @pistacha-git
# Built for precision reconnaissance within controlled and ethical offensive security environments.
# Version: 3.0 | https://github.com/pistacha-git

# Color codes for terminal output
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' 
P='\033[0;35m' C='\033[0;36m' NC='\033[0m'

# Global variables
DETECTED_VERSION=""
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
declare -A USERS USER_IDS

banner() {
echo -e "${C}╔══════════════════════════════════════════════════════════════╗"
echo -e "║ ╦ ╦╔═╗  ╔═╗╔╗╔╦ ╦╔╦╗╔═╗╦═╗╔═╗╔╦╗╔═╗╦═╗                       ║"
echo -e "║ ║║║╠═╝  ║╣ ║║║║ ║║║║║╣ ╠╦╝╠═╣ ║ ║ ║╠╦╝   ${P}v3.0${C}                ║"
echo -e "║ ╚╩╝╩    ╚═╝╝╚╝╚═╝╩ ╩╚═╝╩╚═╩ ╩ ╩ ╚═╝╩╚═                       ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║ ${Y}WordPress Reconnaissance Framework${C}                           ║"
echo -e "║ ${G}Crafted by @pistacha-git${C}                                     ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Check for required dependencies
check_deps() {
    local missing=()
    for dep in curl grep awk sed; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    [ ${#missing[@]} -ne 0 ] && { echo -e "${R}[!] Missing: ${missing[*]}${NC}"; exit 1; }
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
    log "${B}[*] Checking WordPress...${NC}"
    local page=$(fetch "$TARGET")
    local score=0
    
    echo "$page" | grep -iq "wp-content" && ((score++))
    echo "$page" | grep -iq "wp-includes" && ((score++))
    [ "$(http_code "$TARGET/wp-login.php")" = "200" ] && ((score++))
    
    [ $score -ge 2 ] && { log "${G}[+] WordPress detected ($score/3 indicators)${NC}\n"; return 0; }
    log "${R}[!] Not WordPress ($score/3 indicators)${NC}"; return 1
}

# Detect WordPress version using multiple methods
detect_version() {
    log "${B}[*] Detecting version...${NC}"
    local page=$(fetch "$TARGET")
    
    # Method 1: Meta generator tag
    local ver=$(echo "$page" | grep -i "generator" | grep -oP 'WordPress[/ ]+\K[0-9.]+' | head -1)
    [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${G}[+] Version (meta): $ver${NC}"; }
    
    # Method 2: readme.html file
    if [ -z "$ver" ]; then
        ver=$(fetch "$TARGET/readme.html" | grep -oP 'Version \K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${G}[+] Version (readme): $ver${NC}"; }
    fi
    
    # Method 3: RSS feed
    if [ -z "$ver" ]; then
        ver=$(fetch "$TARGET/feed/" | grep -oP '<generator>.*WordPress[/ ]+\K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${G}[+] Version (RSS): $ver${NC}"; }
    fi
    
    # Method 4: CSS/JS assets version parameter
    if [ -z "$ver" ]; then
        ver=$(echo "$page" | grep -oP 'wp-includes/[^"]*ver=\K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${G}[+] Version (assets): $ver${NC}"; }
    fi
    
    [ -z "$DETECTED_VERSION" ] && log "${Y}[!] Version hidden${NC}"
    echo ""
}

# User enumeration using multiple techniques
enumerate_users() {
    log "${B}[*] Enumerating users...${NC}"
    log "${C}[i] Techniques: REST API, Author ID, RSS, Sitemap${NC}"
    local found=0
    
    # Method 1: REST API (most reliable)
    log "${C}[1/4] REST API${NC}"
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
                log "${G}    [+] ID=$id | $name ($slug)${NC}"
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
                log "${G}    [+] ID=$id | $name ($slug)${NC}"
                ((found++))
            }
        done < <(echo "$api" | grep -oP '\{"id":[0-9]+[^}]+\}')
    fi
    [ $found -eq 0 ] && log "${Y}    [-] REST API blocked${NC}"
    
    # Method 2: Author ID enumeration
    log "${C}[2/4] Enumeration /?author=N${NC}"
    local test=$(curl -sI -L -A "$UA" --max-time 2 "$TARGET/?author=1" 2>/dev/null | grep -i "location:")
    
    if [ -n "$test" ]; then
        local auth_found=0
        for i in {1..30}; do  # Test IDs 1-30
            [ $((i % 10)) -eq 0 ] && echo -ne "${B}    Testing ID $i/30...\r${NC}"
            
            local redir=$(curl -sI -L -A "$UA" --max-time 1.5 "$TARGET/?author=$i" 2>/dev/null | 
                         grep -i "location:" | grep -oP 'author/\K[^/\r\n]+')
            
            [ -n "$redir" ] && [ -z "${USERS[$redir]}" ] && {
                USERS["$redir"]="$redir"
                USER_IDS["$redir"]="$i"
                echo -ne "\033[2K"
                log "${G}    [+] ID=$i | $redir${NC}"
                ((found++)); ((auth_found++))
            }
        done
        echo -ne "\033[2K\r"
        [ $auth_found -eq 0 ] && log "${Y}    [-] No new users found${NC}"
    else
        log "${Y}    [-] Enumeration blocked${NC}"
    fi
    
    # Method 3: RSS/Atom feeds
    log "${C}[3/4] RSS/Atom feeds${NC}"
    local feed_found=0
    for feed in "feed/" "feed/atom/"; do
        local authors=$(fetch "$TARGET/$feed" | grep -oP '<dc:creator><!\[CDATA\[\K[^\]]+' | sort -u)
        while IFS= read -r author; do
            [ -n "$author" ] && [ -z "${USERS[$author]}" ] && {
                USERS["$author"]="$author"
                log "${G}    [+] $author (RSS)${NC}"
                ((found++)); ((feed_found++))
            }
        done <<< "$authors"
    done
    [ $feed_found -eq 0 ] && log "${Y}    [-] No authors in feeds${NC}"
    
    # Method 4: XML Sitemap
    log "${C}[4/4] XML Sitemap${NC}"
    local sitemap=$(fetch "$TARGET/wp-sitemap-users-1.xml")
    local sit_found=0
    if echo "$sitemap" | grep -q "<url>"; then
        while IFS= read -r user; do
            [ -n "$user" ] && [ -z "${USERS[$user]}" ] && {
                USERS["$user"]="$user"
                log "${G}    [+] $user (sitemap)${NC}"
                ((found++)); ((sit_found++))
            }
        done < <(echo "$sitemap" | grep -oP 'author/\K[^/<]+' | sort -u)
    fi
    [ $sit_found -eq 0 ] && log "${Y}    [-] No user sitemap${NC}"
    
    # Results summary
    echo ""
    if [ $found -gt 0 ]; then
        log "${G}╔═══════════════════════════════════════╗${NC}"
        log "${G}║  USERS FOUND: $found                       ${NC}"
        log "${G}╚═══════════════════════════════════════╝${NC}"
        log "${C}┌─────┬────────────────────┬──────────────────────┐${NC}"
        log "${C}│ ID  │ Username           │ Display Name         │${NC}"
        log "${C}├─────┼────────────────────┼──────────────────────┤${NC}"
        for slug in "${!USERS[@]}"; do
            printf "${C}│${NC} %-3s ${C}│${NC} %-18s ${C}│${NC} %-20s ${C}│${NC}\n" \
                "${USER_IDS[$slug]:-?}" "${slug:0:18}" "${USERS[$slug]:0:20}"
        done | sort
        log "${C}└─────┴────────────────────┴──────────────────────┘${NC}"
        
        # Save users to separate file if output enabled
        [ -n "$OUTPUT" ] && {
            local ufile="${OUTPUT%.txt}_users.txt"
            printf "%s\n" "${!USERS[@]}" > "$ufile"
            log "${G}[✓] Users saved: $ufile${NC}"
        }
         
        log "\n${Y}[!] WARNING:${NC}"
        log "${Y}    → $found users enumerated${NC}"
        log "${Y}    → Vulnerable to brute force attacks${NC}"
        log "${C}[i] Recommendations:${NC}"
        log "${C}    • Disable REST API user endpoints${NC}"
        log "${C}    • Block /?author=N enumeration${NC}"
        log "${C}    • Enable 2FA${NC}"
    else
        log "${R}[!] Could not enumerate users${NC}"
        log "${G}[+] Enumeration is protected${NC}"
    fi
    echo ""
}

# Plugin enumeration
enumerate_plugins() {
    log "${B}[*] Enumerating plugins...${NC}"
    local page=$(fetch "$TARGET")
    local found=0
    declare -A plugins
    
    # Extract plugins from homepage source
    while IFS= read -r plugin; do
        [ -z "${plugins[$plugin]}" ] && {
            plugins[$plugin]=1
            local ver=$(fetch "$TARGET/wp-content/plugins/$plugin/readme.txt" | 
                       grep -iP 'Stable tag: \K[0-9.]+' | head -1)
            [ -n "$ver" ] && log "${G}    [+] $plugin (v$ver)${NC}" || log "${G}    [+] $plugin${NC}"
            ((found++))
        }
    done < <(echo "$page" | grep -oP 'wp-content/plugins/\K[^/"\?]+' | sort -u)
    
    # Check for common/popular plugins
    local common=("akismet" "contact-form-7" "elementor" "jetpack" "wordpress-seo" 
                  "woocommerce" "wordfence" "classic-editor" "wpforms-lite" "duplicate-post")
    for plugin in "${common[@]}"; do
        [ -z "${plugins[$plugin]}" ] && [ "$(http_code "$TARGET/wp-content/plugins/$plugin/readme.txt")" = "200" ] && {
            plugins[$plugin]=1
            log "${G}    [+] $plugin (common)${NC}"
            ((found++))
        }
    done
    
    [ $found -eq 0 ] && log "${Y}[!] No plugins found${NC}" || log "${G}[✓] Plugins found: $found${NC}"
    echo ""
}

# Theme enumeration
enumerate_themes() {
    log "${B}[*] Enumerating themes...${NC}"
    local page=$(fetch "$TARGET")
    local theme=$(echo "$page" | grep -oP 'wp-content/themes/\K[^/"\?]+' | head -1)
    
    if [ -n "$theme" ]; then
        local css=$(fetch "$TARGET/wp-content/themes/$theme/style.css")
        local ver=$(echo "$css" | grep -iP 'Version:\s*\K[0-9.]+' | head -1)
        local name=$(echo "$css" | grep -iP 'Theme Name:\s*\K[^*\n]+' | head -1 | xargs)
        log "${G}    [+] Active theme: $theme${NC}"
        [ -n "$name" ] && log "${G}        Name: $name${NC}"
        [ -n "$ver" ] && log "${G}        Version: $ver${NC}"
    else
        log "${Y}[!] Theme not detected${NC}"
    fi
    echo ""
}

# XML-RPC vulnerability check
check_xmlrpc() {
    log "${B}[*] Checking XML-RPC...${NC}"
    local resp=$(curl -sX POST -A "$UA" -H "Content-Type: text/xml" \
        -d '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName></methodCall>' \
        "$TARGET/xmlrpc.php" 2>/dev/null)
    
    if echo "$resp" | grep -q "methodResponse"; then
        log "${R}    [!] XML-RPC ENABLED - Security risk${NC}"
        log "${Y}        Risks: Brute force, DDoS, pingback abuse${NC}"
    else
        log "${G}    [+] XML-RPC disabled or restricted${NC}"
    fi
    echo ""
}

# Check for sensitive/exposed files
check_sensitive_files() {
    log "${B}[*] Checking sensitive files...${NC}"
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
                CRITICAL) log "${R}    [!!!] $sev: $file${NC}" ;;
                HIGH) log "${R}    [!!] $sev: $file${NC}" ;;
                MEDIUM) log "${Y}    [!] $sev: $file${NC}" ;;
                *) log "${C}    [i] $sev: $file${NC}" ;;
            esac
            ((exposed++))
        }
    done
    
    [ $exposed -eq 0 ] && log "${G}    [+] No sensitive files exposed${NC}" || 
        log "${Y}    [!] Exposed files: $exposed${NC}"
    echo ""
}

# Check for directory listing vulnerabilities
check_dirs() {
    log "${B}[*] Checking directory listing...${NC}"
    local exposed=0
    for dir in "wp-content/uploads/" "wp-content/plugins/" "wp-content/themes/"; do
        fetch "$TARGET/$dir" | grep -qi "Index of" && {
            log "${R}    [!] Listing enabled: $dir${NC}"
            ((exposed++))
        }
    done
    [ $exposed -eq 0 ] && log "${G}    [+] Directory listing disabled${NC}"
    echo ""
}

# Check admin login page accessibility
check_login() {
    log "${B}[*] Checking admin access...${NC}"
    local code=$(http_code "$TARGET/wp-login.php")
    [ "$code" = "200" ] && log "${G}    [+] Login: $TARGET/wp-login.php${NC}" ||
        log "${Y}    [-] Login HTTP $code${NC}"
    echo ""
}

# Check security headers
check_headers() {
    log "${B}[*] Checking security headers...${NC}"
    local headers=$(curl -sI -A "$UA" "$TARGET" 2>/dev/null)
    
    echo "$headers" | grep -qi "X-Frame-Options" && 
        log "${G}    [+] X-Frame-Options${NC}" || 
        log "${Y}    [-] X-Frame-Options (clickjacking risk)${NC}"
    
    echo "$headers" | grep -qi "Strict-Transport-Security" && 
        log "${G}    [+] HSTS${NC}" || 
        log "${Y}    [-] HSTS (recommended for HTTPS)${NC}"
    
    echo "$headers" | grep -qi "X-Powered-By" && {
        local pw=$(echo "$headers" | grep -i "X-Powered-By" | cut -d: -f2 | xargs)
        log "${Y}    [-] X-Powered-By exposed: $pw${NC}"
    } || log "${G}    [+] X-Powered-By hidden${NC}"
    
    echo ""
}

# SSL/TLS configuration check
check_ssl() {
    log "${B}[*] Checking SSL/TLS...${NC}"
    if [[ "$TARGET" =~ ^https:// ]]; then
        log "${G}    [+] Site uses HTTPS${NC}"
        local http="${TARGET/https:/http:}"
        curl -sI -L -A "$UA" "$http" 2>/dev/null | grep -qi "location.*https" && 
            log "${G}    [+] HTTP redirects to HTTPS${NC}" || 
            log "${Y}    [!] HTTP does NOT redirect to HTTPS${NC}"
    else
        log "${R}    [!] Site uses HTTP (unencrypted)${NC}"
    fi
    echo ""
}

# Quick vulnerability/misconfiguration scan
scan_vulns() {
    log "${B}[*] Scanning misconfigurations...${NC}"
    
    # User enumeration vulnerability
    curl -sI -L -A "$UA" "$TARGET/?author=1" 2>/dev/null | grep -qi "author/" && 
        log "${R}    [!] User enumeration possible (/?author=N)${NC}" || 
        log "${G}    [+] /?author=N enumeration blocked${NC}"
    
    # REST API user disclosure
    fetch "$TARGET/wp-json/wp/v2/users" | grep -q '"id"' && 
        log "${R}    [!] REST API exposes users${NC}" || 
        log "${G}    [+] REST API users protected${NC}"
    
    # Debug log exposure
    [ "$(http_code "$TARGET/wp-content/debug.log")" = "200" ] && 
        log "${R}    [!] debug.log PUBLIC${NC}"
    
    echo ""
}

# Generate final summary report
generate_summary() {
    log "${P}═══════════════════════════════════════════${NC}"
    log "${P}         ENUMERATION SUMMARY${NC}"
    log "${P}═══════════════════════════════════════════${NC}"
    log "${C}Target:${NC} $TARGET"
    log "${C}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    log "${C}WP Version:${NC} ${DETECTED_VERSION:-Unknown}"
    log "${C}Users:${NC} ${#USERS[@]}"
    
    [ -n "$OUTPUT" ] && log "\n${G}[✓] Report saved: $OUTPUT${NC}"
    
    log "\n${C}Next steps:${NC}"
    log "${C}  1. Full WPScan:${NC} ${Y}wpscan --url $TARGET -e ap,at,u${NC}"
    log "${C}  2. Review plugins/themes vs CVE${NC}"
    log "${C}  3. Configuration analysis${NC}"
    
    log "\n${P}═══════════════════════════════════════════${NC}"
    log "${R}⚠  Authorized testing only${NC}"
    log "${P}   github.com/pistacha-git | @pistacha-git${NC}"
    log "${P}═══════════════════════════════════════════${NC}"
}

# Main execution function
main() {
    banner
    
    # Usage instructions if no arguments provided
    [ $# -lt 1 ] && {
        echo -e "${R}Usage: $0 <target_url> [output_file]${NC}"
        echo -e "\n${Y}Examples:${NC}"
        echo -e "  $0 http://example.com"
        echo -e "  $0 https://wordpress.site report.txt"
        echo -e "\n${C}Engineered by @pistacha-git${NC}"
        echo -e "${C}GitHub: github.com/pistacha-git${NC}"
        exit 1
    }
    
    TARGET="${1%/}"
    OUTPUT="$2"
    
    # Validate URL format
    [[ ! "$TARGET" =~ ^https?:// ]] && {
        echo -e "${R}[!] Invalid URL. Use http:// or https://${NC}"
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
        log "${G}[+] Output saving to: $OUTPUT${NC}\n"
    }
    
    log "${G}[+] Starting enumeration: $TARGET${NC}\n"
    
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
    
    log "\n${G}[✓] Enumeration completed${NC}\n"
}

# Trap keyboard interrupts
trap 'echo -e "\n${R}[!] Interrupted${NC}"; exit 1' INT TERM
main "$@"
