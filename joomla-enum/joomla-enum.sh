#!/bin/bash

# Joomla Enumeration Script - Professional Edition
# Crafted by @pistacha-git
# Built for precision reconnaissance within controlled and ethical offensive security environments.
# Version: 1.0 | https://github.com/pistacha-git

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[0;95m'
ORANGE='\033[38;5;208m'
BRIGHT_BLUE='\033[1;34m'
NC='\033[0m'

# Global variables
DETECTED_VERSION=""
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
declare -A USERS EXTENSIONS

# Banner
banner() {
    echo -e "${ORANGE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        ██╗ ██████╗  ██████╗ ███╗   ███╗██╗      █████╗    ║
║        ██║██╔═══██╗██╔═══██╗████╗ ████║██║     ██╔══██╗   ║
║        ██║██║   ██║██║   ██║██╔████╔██║██║     ███████║   ║
║   ██   ██║██║   ██║██║   ██║██║╚██╔╝██║██║     ██╔══██║   ║
║   ╚█████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██║   ║
║    ╚════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝   ║
║                                                           ║
║         ███████╗███╗   ██╗██╗   ██╗███╗   ███╗            ║
║         ██╔════╝████╗  ██║██║   ██║████╗ ████║            ║
║         █████╗  ██╔██╗ ██║██║   ██║██╔████╔██║            ║
║         ██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║            ║
║         ███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║            ║
║         ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝            ║
║                                                           ║
║         Joomla Advanced Enumeration Tool v3.0             ║
║               Crafted by @pistacha-git                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
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

# Check if target is running Joomla
check_joomla() {
    log "${BRIGHT_BLUE}[*] Checking Joomla...${NC}"
    local page=$(fetch "$TARGET")
    local score=0
    
    echo "$page" | grep -iq "joomla" && ((score++))
    echo "$page" | grep -iq "/media/system/js/" && ((score++))
    [ "$(http_code "$TARGET/administrator/")" = "200" ] && ((score++))
    [ "$(http_code "$TARGET/administrator/manifests/files/joomla.xml")" = "200" ] && ((score++))
    
    [ $score -ge 2 ] && { log "${GREEN}[+] Joomla detected ($score/4 indicators)${NC}\n"; return 0; }
    log "${RED}[!] Not Joomla ($score/4 indicators)${NC}"; return 1
}

# Detect Joomla version using multiple methods
detect_version() {
    log "${BRIGHT_BLUE}[*] Detecting Joomla version...${NC}"
    local page=$(fetch "$TARGET")
    
    # Method 1: joomla.xml manifest file
    local xml=$(fetch "$TARGET/administrator/manifests/files/joomla.xml")
    local ver=$(echo "$xml" | grep -oP '<version>\K[0-9.]+' | head -1)
    [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (manifest): $ver${NC}"; }
    
    # Method 2: language XML files
    if [ -z "$ver" ]; then
        ver=$(fetch "$TARGET/language/en-GB/en-GB.xml" | grep -oP '<version>\K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (language): $ver${NC}"; }
    fi
    
    # Method 3: Meta generator tag
    if [ -z "$ver" ]; then
        ver=$(echo "$page" | grep -i "generator" | grep -oP 'Joomla[!]? \K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (meta): $ver${NC}"; }
    fi
    
    # Method 4: README.txt file
    if [ -z "$ver" ]; then
        ver=$(fetch "$TARGET/README.txt" | grep -oP 'Joomla! \K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (README): $ver${NC}"; }
    fi
    
    # Method 5: media/system/js files version
    if [ -z "$ver" ]; then
        ver=$(echo "$page" | grep -oP '/media/system/js/.*?ver=\K[0-9.]+' | head -1)
        [ -n "$ver" ] && { DETECTED_VERSION="$ver"; log "${GREEN}[+] Version (assets): $ver${NC}"; }
    fi
    
    [ -z "$DETECTED_VERSION" ] && log "${YELLOW}[!] Version hidden or not detected${NC}"
    echo ""
}

# Enumerate users through various methods
enumerate_users() {
    log "${BRIGHT_BLUE}[*] Enumerating users...${NC}"
    log "${CYAN}[i] Techniques: Login error, Author pages, RSS, Contact forms${NC}"
    local found=0
    
    # Method 1: Login error-based enumeration
    log "${CYAN}[1/4] Login error analysis${NC}"
    local common_users=("admin" "administrator" "root" "user" "test" "demo" "joomla")
    
    for user in "${common_users[@]}"; do
        local login_resp=$(curl -sL -A "$UA" -X POST "$TARGET/administrator/index.php" \
            -d "username=$user&passwd=wrongpassword&option=com_login&task=login" \
            --max-time 5 2>/dev/null)
        
        if echo "$login_resp" | grep -qi "password.*incorrect\|contraseña.*incorrecta"; then
            USERS["$user"]="Confirmed (login error)"
            log "${GREEN}    [+] User exists: $user${NC}"
            ((found++))
        fi
    done
    [ $found -eq 0 ] && log "${YELLOW}    [-] No users via login errors${NC}"
    
    # Method 2: Author pages enumeration
    log "${CYAN}[2/4] Author pages (/index.php?option=com_content&view=article&id=N)${NC}"
    local auth_found=0
    for i in {1..20}; do
        local article=$(fetch "$TARGET/index.php?option=com_content&view=article&id=$i")
        local author=$(echo "$article" | grep -oP 'Written by:?\s*<[^>]*>\K[^<]+' | head -1 | xargs)
        
        if [ -n "$author" ] && [ -z "${USERS[$author]}" ]; then
            USERS["$author"]="From article $i"
            log "${GREEN}    [+] Author: $author (article $i)${NC}"
            ((found++)); ((auth_found++))
        fi
    done
    [ $auth_found -eq 0 ] && log "${YELLOW}    [-] No authors in articles${NC}"
    
    # Method 3: RSS feeds
    log "${CYAN}[3/4] RSS/Atom feeds${NC}"
    local feed_found=0
    for feed in "?format=feed&type=rss" "?format=feed&type=atom"; do
        local authors=$(fetch "$TARGET/$feed" | grep -oP '<author>\K[^<]+|<dc:creator>\K[^<]+' | sort -u)
        while IFS= read -r author; do
            [ -n "$author" ] && [ -z "${USERS[$author]}" ] && {
                USERS["$author"]="From RSS feed"
                log "${GREEN}    [+] $author (RSS)${NC}"
                ((found++)); ((feed_found++))
            }
        done <<< "$authors"
    done
    [ $feed_found -eq 0 ] && log "${YELLOW}    [-] No authors in feeds${NC}"
    
    # Method 4: Contact component users
    log "${CYAN}[4/4] Contact component${NC}"
    local contact=$(fetch "$TARGET/index.php?option=com_contact&view=category&id=1")
    local cont_found=0
    local contacts=$(echo "$contact" | grep -oP 'view=contact[^"]*id=\K[0-9]+' | sort -u)
    
    while IFS= read -r cid; do
        [ -n "$cid" ] && {
            local cpage=$(fetch "$TARGET/index.php?option=com_contact&view=contact&id=$cid")
            local cname=$(echo "$cpage" | grep -oP '<h1[^>]*>\K[^<]+' | head -1 | xargs)
            [ -n "$cname" ] && [ -z "${USERS[$cname]}" ] && {
                USERS["$cname"]="Contact profile"
                log "${GREEN}    [+] $cname (contact)${NC}"
                ((found++)); ((cont_found++))
            }
        }
    done <<< "$contacts"
    [ $cont_found -eq 0 ] && log "${YELLOW}    [-] No contact profiles${NC}"
    
    # Results summary
    echo ""
    if [ $found -gt 0 ]; then
        log "${GREEN}╔═══════════════════════════════════════╗${NC}"
        log "${GREEN}║  USERS FOUND: $found                       ${NC}"
        log "${GREEN}╚═══════════════════════════════════════╝${NC}"
        log "${CYAN}┌─────────────────────────┬──────────────────────────┐${NC}"
        log "${CYAN}│ Username                │ Source                   │${NC}"
        log "${CYAN}├─────────────────────────┼──────────────────────────┤${NC}"
        for user in "${!USERS[@]}"; do
            printf "${CYAN}│${NC} %-23s ${CYAN}│${NC} %-24s ${CYAN}│${NC}\n" \
                "${user:0:23}" "${USERS[$user]:0:24}"
        done | sort
        log "${CYAN}└─────────────────────────┴──────────────────────────┘${NC}"
        
        # Save users to separate file
        [ -n "$OUTPUT" ] && {
            local ufile="${OUTPUT%.txt}_users.txt"
            printf "%s\n" "${!USERS[@]}" > "$ufile"
            log "${GREEN}[✓] Users saved: $ufile${NC}"
        }
        
        log "\n${YELLOW}[!] WARNING:${NC}"
        log "${YELLOW}    → $found users enumerated${NC}"
        log "${YELLOW}    → Vulnerable to brute force attacks${NC}"
        log "${CYAN}[i] Recommendations:${NC}"
        log "${CYAN}    • Use strong, unique usernames (not 'admin')${NC}"
        log "${CYAN}    • Enable 2FA/MFA${NC}"
        log "${CYAN}    • Implement rate limiting${NC}"
        log "${CYAN}    • Monitor failed login attempts${NC}"
    else
        log "${RED}[!] Could not enumerate users${NC}"
        log "${GREEN}[+] Enumeration appears protected${NC}"
    fi
    echo ""
}

# Component and module enumeration
enumerate_extensions() {
    log "${BRIGHT_BLUE}[*] Enumerating extensions...${NC}"
    local page=$(fetch "$TARGET")
    local found=0
    
    # Extract components from source
    log "${CYAN}[*] Components:${NC}"
    local comp_found=0
    while IFS= read -r comp; do
        [ -z "${EXTENSIONS[$comp]}" ] && {
            EXTENSIONS[$comp]="component"
            local manifest=$(fetch "$TARGET/administrator/components/$comp/$comp.xml")
            local ver=$(echo "$manifest" | grep -oP '<version>\K[0-9.]+' | head -1)
            [ -n "$ver" ] && log "${GREEN}    [+] $comp (v$ver)${NC}" || log "${GREEN}    [+] $comp${NC}"
            ((found++)); ((comp_found++))
        }
    done < <(echo "$page" | grep -oP 'option=com_\K[a-z0-9_]+' | sort -u)
    [ $comp_found -eq 0 ] && log "${YELLOW}    [-] No components detected in source${NC}"
    
    # Check common vulnerable components
    log "\n${CYAN}[*] Checking common components:${NC}"
    local common_comps=("com_content" "com_users" "com_contact" "com_finder" 
                        "com_media" "com_modules" "com_plugins" "com_templates"
                        "com_fabrik" "com_community" "com_kunena" "com_jce")
    
    for comp in "${common_comps[@]}"; do
        local comp_path="components/$comp"
        if [ "$(http_code "$TARGET/$comp_path")" = "200" ] || [ "$(http_code "$TARGET/administrator/$comp_path")" = "200" ]; then
            [ -z "${EXTENSIONS[$comp]}" ] && {
                EXTENSIONS[$comp]="component (common)"
                log "${GREEN}    [+] $comp${NC}"
                ((found++))
            }
        fi
    done
    
    # Enumerate modules
    log "\n${CYAN}[*] Modules:${NC}"
    local mod_found=0
    while IFS= read -r mod; do
        [ -n "$mod" ] && [ -z "${EXTENSIONS[$mod]}" ] && {
            EXTENSIONS[$mod]="module"
            log "${GREEN}    [+] $mod${NC}"
            ((found++)); ((mod_found++))
        }
    done < <(echo "$page" | grep -oP 'modules/mod_\K[a-z0-9_]+' | sort -u)
    [ $mod_found -eq 0 ] && log "${YELLOW}    [-] No modules in source${NC}"
    
    # Enumerate plugins
    log "\n${CYAN}[*] Plugins:${NC}"
    local plug_found=0
    for plugin_type in "system" "content" "user" "authentication" "editors"; do
        local plugins=$(echo "$page" | grep -oP "plugins/$plugin_type/\K[a-z0-9_]+" | sort -u)
        while IFS= read -r plug; do
            [ -n "$plug" ] && [ -z "${EXTENSIONS[$plug]}" ] && {
                EXTENSIONS[$plug]="plugin ($plugin_type)"
                log "${GREEN}    [+] $plug ($plugin_type)${NC}"
                ((found++)); ((plug_found++))
            }
        done <<< "$plugins"
    done
    [ $plug_found -eq 0 ] && log "${YELLOW}    [-] No plugins detected${NC}"
    
    echo ""
    [ $found -gt 0 ] && log "${GREEN}[✓] Total extensions found: $found${NC}\n" || 
        log "${YELLOW}[!] No extensions detected${NC}\n"
}

# Template detection
detect_template() {
    log "${BRIGHT_BLUE}[*] Detecting template...${NC}"
    local page=$(fetch "$TARGET")
    local template=$(echo "$page" | grep -oP 'templates/\K[^/"\?]+' | head -1)
    
    if [ -n "$template" ]; then
        local xml=$(fetch "$TARGET/templates/$template/templateDetails.xml")
        local ver=$(echo "$xml" | grep -oP '<version>\K[0-9.]+' | head -1)
        local tname=$(echo "$xml" | grep -oP '<name>\K[^<]+' | head -1)
        local author=$(echo "$xml" | grep -oP '<author>\K[^<]+' | head -1)
        
        log "${GREEN}    [+] Active template: $template${NC}"
        [ -n "$tname" ] && log "${GREEN}        Name: $tname${NC}"
        [ -n "$ver" ] && log "${GREEN}        Version: $ver${NC}"
        [ -n "$author" ] && log "${GREEN}        Author: $author${NC}"
    else
        log "${YELLOW}[!] Template not detected${NC}"
    fi
    echo ""
}

# Check for sensitive/exposed files
check_sensitive_files() {
    log "${BRIGHT_BLUE}[*] Checking sensitive files...${NC}"
    local exposed=0
    local files=(
        "configuration.php:CRITICAL" "configuration.php~:CRITICAL" "configuration.php.bak:CRITICAL"
        ".env:CRITICAL" "backup.sql:CRITICAL" "database.sql:CRITICAL" "joomla.sql:CRITICAL"
        "backup.zip:HIGH" "joomla_backup.zip:HIGH" "site_backup.tar.gz:HIGH"
        "htaccess.txt:MEDIUM" ".htaccess.bak:HIGH"
        "README.txt:INFO" "LICENSE.txt:INFO" "CHANGELOG.txt:INFO"
        ".git/config:HIGH" ".svn/entries:HIGH"
        "phpinfo.php:CRITICAL" "info.php:CRITICAL"
        "administrator/logs/error.php:MEDIUM" "logs/error.log:MEDIUM"
        "tmp/:MEDIUM" "cache/:MEDIUM"
    )
    
    for entry in "${files[@]}"; do
        IFS=':' read -r file sev <<< "$entry"
        local code=$(http_code "$TARGET/$file")
        if [ "$code" = "200" ] || [ "$code" = "403" ]; then
            case $sev in
                CRITICAL) log "${RED}    [!!!] $sev: $file [HTTP $code]${NC}" ;;
                HIGH) log "${RED}    [!!] $sev: $file [HTTP $code]${NC}" ;;
                MEDIUM) log "${YELLOW}    [!] $sev: $file [HTTP $code]${NC}" ;;
                *) log "${CYAN}    [i] $sev: $file [HTTP $code]${NC}" ;;
            esac
            ((exposed++))
        fi
    done
    
    [ $exposed -eq 0 ] && log "${GREEN}    [+] No sensitive files exposed${NC}" || 
        log "${YELLOW}    [!] Exposed files/paths: $exposed${NC}"
    echo ""
}

# Check directory listing
check_dirs() {
    log "${BRIGHT_BLUE}[*] Checking directory listing...${NC}"
    local exposed=0
    local dirs=("images/" "media/" "tmp/" "cache/" "logs/" "administrator/logs/" 
                "components/" "modules/" "plugins/" "templates/")
    
    for dir in "${dirs[@]}"; do
        local content=$(fetch "$TARGET/$dir")
        echo "$content" | grep -qi "Index of" && {
            log "${RED}    [!] Listing enabled: $dir${NC}"
            ((exposed++))
        }
    done
    [ $exposed -eq 0 ] && log "${GREEN}    [+] Directory listing disabled${NC}"
    echo ""
}

# Check admin panel accessibility
check_admin() {
    log "${BRIGHT_BLUE}[*] Checking admin panel...${NC}"
    local admin_paths=("administrator/" "admin/" "administrator/index.php")
    
    for path in "${admin_paths[@]}"; do
        local code=$(http_code "$TARGET/$path")
        if [ "$code" = "200" ]; then
            log "${GREEN}    [+] Admin panel: $TARGET/$path [HTTP $code]${NC}"
            
            # Check if login page is accessible
            local admin_page=$(fetch "$TARGET/$path")
            echo "$admin_page" | grep -qi "joomla" && 
                log "${YELLOW}        [!] Admin login publicly accessible${NC}"
        fi
    done
    echo ""
}

# Check configuration disclosure
check_config_disclosure() {
    log "${BRIGHT_BLUE}[*] Checking configuration disclosure...${NC}"
    local disclosed=0
    
    # Check for exposed configuration.php
    local config=$(fetch "$TARGET/configuration.php")
    if echo "$config" | grep -q "JConfig\|public.*password\|dbtype"; then
        log "${RED}    [!!!] CRITICAL: configuration.php is readable!${NC}"
        log "${RED}        Database credentials may be exposed${NC}"
        ((disclosed++))
    else
        log "${GREEN}    [+] configuration.php protected${NC}"
    fi
    
    # Check for exposed configuration backups
    for backup in "configuration.php~" "configuration.php.bak" "configuration.php.old" "configuration.php.save"; do
        [ "$(http_code "$TARGET/$backup")" = "200" ] && {
            log "${RED}    [!!!] CRITICAL: $backup accessible!${NC}"
            ((disclosed++))
        }
    done
    
    [ $disclosed -eq 0 ] && log "${GREEN}    [+] No configuration disclosure${NC}"
    echo ""
}

# Check security headers
check_headers() {
    log "${BRIGHT_BLUE}[*] Checking security headers...${NC}"
    local headers=$(curl -sI -A "$UA" "$TARGET" 2>/dev/null)
    
    echo "$headers" | grep -qi "X-Frame-Options" && 
        log "${GREEN}    [+] X-Frame-Options present${NC}" || 
        log "${YELLOW}    [-] X-Frame-Options missing (clickjacking risk)${NC}"
    
    echo "$headers" | grep -qi "Content-Security-Policy" && 
        log "${GREEN}    [+] Content-Security-Policy present${NC}" || 
        log "${YELLOW}    [-] Content-Security-Policy missing${NC}"
    
    echo "$headers" | grep -qi "Strict-Transport-Security" && 
        log "${GREEN}    [+] HSTS enabled${NC}" || 
        log "${YELLOW}    [-] HSTS missing (for HTTPS sites)${NC}"
    
    echo "$headers" | grep -qi "X-Content-Type-Options" && 
        log "${GREEN}    [+] X-Content-Type-Options present${NC}" || 
        log "${YELLOW}    [-] X-Content-Type-Options missing${NC}"
    
    # Check for information disclosure
    echo "$headers" | grep -qi "X-Powered-By" && {
        local pw=$(echo "$headers" | grep -i "X-Powered-By" | cut -d: -f2 | xargs)
        log "${YELLOW}    [-] X-Powered-By exposed: $pw${NC}"
    } || log "${GREEN}    [+] X-Powered-By hidden${NC}"
    
    echo "$headers" | grep -qi "Server:" && {
        local srv=$(echo "$headers" | grep -i "^Server:" | cut -d: -f2 | xargs)
        log "${CYAN}    [i] Server: $srv${NC}"
    }
    
    echo ""
}

# Check SSL/TLS configuration
check_ssl() {
    log "${BRIGHT_BLUE}[*] Checking SSL/TLS...${NC}"
    if [[ "$TARGET" =~ ^https:// ]]; then
        log "${GREEN}    [+] Site uses HTTPS${NC}"
        
        # Check HTTP to HTTPS redirect
        local http="${TARGET/https:/http:}"
        curl -sI -L -A "$UA" "$http" 2>/dev/null | grep -qi "location.*https" && 
            log "${GREEN}    [+] HTTP redirects to HTTPS${NC}" || 
            log "${YELLOW}    [!] HTTP does NOT redirect to HTTPS${NC}"
    else
        log "${RED}    [!] Site uses HTTP (unencrypted)${NC}"
        log "${YELLOW}        Credentials transmitted in cleartext!${NC}"
    fi
    echo ""
}

# Scan for common vulnerabilities
scan_vulns() {
    log "${BRIGHT_BLUE}[*] Scanning for misconfigurations...${NC}"
    local vulns=0
    
    # Check if registration is enabled
    local reg_page=$(fetch "$TARGET/index.php?option=com_users&view=registration")
    echo "$reg_page" | grep -qi "registration\|register" && {
        log "${YELLOW}    [!] User registration may be enabled${NC}"
        ((vulns++))
    }
    
    # Check for exposed /tmp directory
    fetch "$TARGET/tmp/" | grep -qi "Index of" && {
        log "${RED}    [!] /tmp/ directory listing exposed${NC}"
        ((vulns++))
    }
    
    # Check for exposed /cache directory
    fetch "$TARGET/cache/" | grep -qi "Index of" && {
        log "${RED}    [!] /cache/ directory listing exposed${NC}"
        ((vulns++))
    }
    
    # Check for debug mode
    local page=$(fetch "$TARGET")
    echo "$page" | grep -qi "JDEBUG" && {
        log "${RED}    [!] Debug mode may be enabled (JDEBUG)${NC}"
        ((vulns++))
    }
    
    # Check for exposed installation directory
    [ "$(http_code "$TARGET/installation/")" != "404" ] && {
        log "${RED}    [!] /installation/ directory still present${NC}"
        log "${YELLOW}        Recommendation: Remove after installation${NC}"
        ((vulns++))
    }
    
    # Check for test/dev installations
    for test_dir in "test" "dev" "demo" "backup" "old"; do
        [ "$(http_code "$TARGET/$test_dir/")" = "200" ] && {
            log "${YELLOW}    [!] Potential test installation: /$test_dir/${NC}"
            ((vulns++))
        }
    done
    
    [ $vulns -eq 0 ] && log "${GREEN}    [+] No obvious misconfigurations found${NC}"
    echo ""
}

# Check robots.txt and security.txt
check_info_files() {
    log "${BRIGHT_BLUE}[*] Checking information disclosure files...${NC}"
    
    # Check robots.txt
    local robots=$(fetch "$TARGET/robots.txt")
    if [ -n "$robots" ]; then
        log "${GREEN}    [+] robots.txt found${NC}"
        local disallowed=$(echo "$robots" | grep -i "Disallow:" | wc -l)
        [ $disallowed -gt 0 ] && log "${CYAN}        Contains $disallowed disallowed paths${NC}"
    fi
    
    # Check security.txt
    local security=$(fetch "$TARGET/.well-known/security.txt")
    [ -n "$security" ] && log "${GREEN}    [+] security.txt found${NC}"
    
    # Check humans.txt
    [ "$(http_code "$TARGET/humans.txt")" = "200" ] && log "${CYAN}    [i] humans.txt found${NC}"
    
    echo ""
}

# Generate final summary
generate_summary() {
    log "${ORANGE}═══════════════════════════════════════════${NC}"
    log "${ORANGE}         ENUMERATION SUMMARY${NC}"
    log "${ORANGE}═══════════════════════════════════════════${NC}"
    log "${CYAN}Target:${NC} $TARGET"
    log "${CYAN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    log "${CYAN}Joomla Version:${NC} ${DETECTED_VERSION:-Unknown}"
    log "${CYAN}Users Found:${NC} ${#USERS[@]}"
    log "${CYAN}Extensions Found:${NC} ${#EXTENSIONS[@]}"
    
    [ -n "$OUTPUT" ] && log "\n${GREEN}[✓] Report saved: $OUTPUT${NC}"
    
    log "\n${CYAN}Recommended next steps:${NC}"
    log "${CYAN}  1. Vulnerability scanning:${NC} ${YELLOW}joomscan -u $TARGET${NC}"
    log "${CYAN}  2. Review extensions against CVE database${NC}"
    log "${CYAN}  3. Password testing (authorized only)${NC}"
    log "${CYAN}  4. Manual configuration review${NC}"
    
    log "\n${ORANGE}═══════════════════════════════════════════${NC}"
    log "${RED}⚠  AUTHORIZED TESTING ONLY${NC}"
    log "${ORANGE}   github.com/pistacha-git | @pistacha-git${NC}"
    log "${ORANGE}═══════════════════════════════════════════${NC}"
}

# Main execution
main() {
    banner
    
    # Usage check
    [ $# -lt 1 ] && {
        echo -e "${RED}Usage: $0 <target_url> [output_file]${NC}"
        echo -e "\n${YELLOW}Examples:${NC}"
        echo -e "  $0 http://example.com"
        echo -e "  $0 https://joomla-site.com report.txt"
        echo -e "\n${CYAN}Engineered by @pistacha-git${NC}"
        echo -e "${CYAN}GitHub: github.com/pistacha-git${NC}"
        exit 1
    }
    
    TARGET="${1%/}"
    OUTPUT="$2"
    
    # Validate URL
    [[ ! "$TARGET" =~ ^https?:// ]] && {
        echo -e "${RED}[!] Invalid URL. Use http:// or https://${NC}"
        exit 1
    }
    
    check_deps
    
    # Create output file
    [ -n "$OUTPUT" ] && {
        cat > "$OUTPUT" << EOF
╔══════════════════════════════════════════════════════════╗
║          Joomla Security Enumeration Report             ║
╚══════════════════════════════════════════════════════════╝

Target: $TARGET
Date: $(date '+%Y-%m-%d %H:%M:%S')
Analyst: @pistacha-git
Tool: Joomla-Enumerator v1.0 Professional Edition

═══════════════════════════════════════════════════════════

EOF
        log "${GREEN}[+] Output saving to: $OUTPUT${NC}\n"
    }
    
    log "${GREEN}[+] Starting Joomla enumeration: $TARGET${NC}\n"
    
    # Execute enumeration modules
    check_joomla || exit 1
    detect_version
    enumerate_users
    enumerate_extensions
    detect_template
    check_sensitive_files
    check_config_disclosure
    check_dirs
    check_admin
    check_headers
    check_ssl
    check_info_files
    scan_vulns
    generate_summary
    
    log "\n${GREEN}[✓] Enumeration completed${NC}\n"
}

# Trap interrupts
trap 'echo -e "\n${RED}[!] Interrupted${NC}"; exit 1' INT TERM
main "$@"
