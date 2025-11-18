#!/bin/bash

# Drupal Full Enumeration Script - Advanced Edition
# Crafted by @pistacha-git
# Version: 3.0 | https://github.com/pistacha-git
# Usage: ./drupal_enum.sh <target_url> [output_file]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[0;95m'
NC='\033[0m'

# Global variables
DETECTED_VERSION=""
DETECTED_CORE=""
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
TEMP_DIR="/tmp/drupal_enum_$$"

# Banner
banner() {
    echo -e "${MAGENTA}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ██████╗ ██████╗ ██╗   ██╗██████╗  █████╗ ██╗            ║
║   ██╔══██╗██╔══██╗██║   ██║██╔══██╗██╔══██╗██║            ║
║   ██║  ██║██████╔╝██║   ██║██████╔╝███████║██║            ║
║   ██║  ██║██╔══██╗██║   ██║██╔═══╝ ██╔══██║██║            ║
║   ██████╔╝██║  ██║╚██████╔╝██║     ██║  ██║███████╗       ║
║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝       ║
║                                                           ║
║         ███████╗███╗   ██╗██╗   ██╗███╗   ███╗            ║
║         ██╔════╝████╗  ██║██║   ██║████╗ ████║            ║
║         █████╗  ██╔██╗ ██║██║   ██║██╔████╔██║            ║
║         ██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║            ║
║         ███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║            ║
║         ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝            ║
║                                                           ║
║         Drupal Advanced Enumeration Tool v3.0             ║
║               Crafted by @pistacha-git                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check dependencies
check_deps() {
    local deps=("curl" "grep" "awk" "sed")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}[!] Missing dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}[*] Install with: sudo apt install ${missing[*]}${NC}"
        exit 1
    fi
    
    mkdir -p "$TEMP_DIR"
}

cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null
}

trap cleanup EXIT

validate_url() {
    if [[ ! "$1" =~ ^https?:// ]]; then
        echo -e "${RED}[!] Invalid URL format. Use http:// or https://${NC}"
        exit 1
    fi
}

log() {
    local msg="$1"
    echo -e "$msg"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$msg" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT_FILE"
    fi
}

fetch_url() {
    local url="$1"
    local follow_redirects="${2:-true}"
    
    if [ "$follow_redirects" = "true" ]; then
        curl -s -L -A "$USER_AGENT" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
             --max-time 10 --connect-timeout 5 "$url" 2>/dev/null
    else
        curl -s -A "$USER_AGENT" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
             --max-time 10 --connect-timeout 5 "$url" 2>/dev/null
    fi
}

check_drupal() {
    log "${BLUE}[*] Checking if target is Drupal...${NC}"
    
    local homepage=$(fetch_url "$TARGET")
    local indicators=0
    
    if echo "$homepage" | grep -iq "drupal"; then ((indicators++)); fi
    if echo "$homepage" | grep -iq "sites/default/files"; then ((indicators++)); fi
    if echo "$homepage" | grep -iq "misc/drupal.js"; then ((indicators++)); fi
    if echo "$homepage" | grep -q 'content="Drupal'; then ((indicators++)); fi
    
    local changelog=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/CHANGELOG.txt")
    if [ "$changelog" = "200" ]; then ((indicators++)); fi
    
    local install=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/install.php")
    if [ "$install" = "200" ] || [ "$install" = "403" ]; then ((indicators++)); fi
    
    local user_login=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/user/login")
    if [ "$user_login" = "200" ]; then ((indicators++)); fi
    
    if [ $indicators -ge 2 ]; then
        log "${GREEN}[+] Drupal detected! - Confidence: $indicators/7 indicators${NC}\n"
        return 0
    else
        log "${RED}[!] Target doesn't appear to be Drupal - Found $indicators/7 indicators${NC}"
        return 1
    fi
}

detect_version() {
    log "${BLUE}[*] Detecting Drupal version...${NC}"
    log "${CYAN}[>] Trying multiple detection methods...${NC}\n"
    
    local version_found=false
    
    log "${CYAN}    [1] Checking CHANGELOG.txt...${NC}"
    local changelog=$(fetch_url "$TARGET/CHANGELOG.txt")
    if [ -n "$changelog" ]; then
        local version=$(echo "$changelog" | grep -oP 'Drupal \K[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        if [ -n "$version" ]; then
            log "${GREEN}        [+] Version from CHANGELOG.txt: ${version}${NC}"
            DETECTED_VERSION="$version"
            DETECTED_CORE=$(echo "$version" | cut -d. -f1)
            version_found=true
        else
            log "${YELLOW}        [-] CHANGELOG.txt found but no version extracted${NC}"
        fi
    else
        log "${YELLOW}        [-] CHANGELOG.txt not accessible${NC}"
    fi
    
    log "${CYAN}    [2] Checking meta generator tag...${NC}"
    local homepage=$(fetch_url "$TARGET")
    local meta_version=$(echo "$homepage" | grep -i "generator" | grep -oP 'Drupal \K[0-9]+(\.[0-9]+)*' | head -1)
    if [ -n "$meta_version" ]; then
        log "${GREEN}        [+] Version from meta tag: ${meta_version}${NC}"
        if [ -z "$DETECTED_VERSION" ]; then
            DETECTED_VERSION="$meta_version"
            DETECTED_CORE=$(echo "$meta_version" | cut -d. -f1)
        fi
        version_found=true
    else
        log "${YELLOW}        [-] No version in meta tag${NC}"
    fi
    
    log "${CYAN}    [3] Checking core JavaScript files...${NC}"
    local js_files=("misc/drupal.js" "core/misc/drupal.js")
    local js_version=""
    for js in "${js_files[@]}"; do
        local js_content=$(fetch_url "$TARGET/$js")
        if [ -n "$js_content" ]; then
            js_version=$(echo "$js_content" | grep -oP 'Drupal \K[0-9]+\.[0-9]+' | head -1)
            if [ -n "$js_version" ]; then
                log "${GREEN}        [+] Version from $js: ${js_version}${NC}"
                if [ -z "$DETECTED_VERSION" ]; then
                    DETECTED_VERSION="$js_version"
                    DETECTED_CORE=$(echo "$js_version" | cut -d. -f1)
                fi
                version_found=true
                break
            fi
        fi
    done
    if [ -z "$js_version" ]; then
        log "${YELLOW}        [-] No version in JS files${NC}"
    fi
    
    log "${CYAN}    [4] Checking for Drupal 8+ indicators...${NC}"
    if echo "$homepage" | grep -q "core/themes/"; then
        log "${GREEN}        [+] Drupal 8+ structure detected${NC}"
        
        if echo "$homepage" | grep -q "drupal-9\|core.*9\."; then
            log "${GREEN}        [+] Drupal 9.x indicators found${NC}"
            if [ -z "$DETECTED_CORE" ]; then
                DETECTED_CORE="9"
            fi
        elif echo "$homepage" | grep -q "drupal-10\|core.*10\."; then
            log "${GREEN}        [+] Drupal 10.x indicators found${NC}"
            if [ -z "$DETECTED_CORE" ]; then
                DETECTED_CORE="10"
            fi
        elif echo "$homepage" | grep -q "drupal-8\|core.*8\."; then
            log "${GREEN}        [+] Drupal 8.x indicators found${NC}"
            if [ -z "$DETECTED_CORE" ]; then
                DETECTED_CORE="8"
            fi
        fi
    else
        log "${YELLOW}        [-] No Drupal 8+ specific indicators${NC}"
    fi
    
    echo ""
    if [ "$version_found" = true ] && [ -n "$DETECTED_VERSION" ]; then
        log "${GREEN}[✓] Drupal Version Detected: ${DETECTED_VERSION}${NC}"
    elif [ -n "$DETECTED_CORE" ]; then
        log "${YELLOW}[!] Drupal Core Version: ${DETECTED_CORE} - exact version hidden${NC}"
    else
        log "${YELLOW}[!] Could not detect Drupal version - may be hidden${NC}"
    fi
    
    echo ""
}

enumerate_users() {
    log "${BLUE}[*] Enumerating Drupal Users${NC}"
    log "${CYAN}[i] Testing multiple enumeration vectors...${NC}\n"
    
    declare -A found_users
    declare -A user_ids
    local total_users=0
    
    log "${CYAN}[>] [1/8] REST API User Enumeration${NC}"
    local api_found=0
    
    local rest_endpoints=(
        "user/1?_format=json"
        "jsonapi/user/user"
        "rest/user?_format=json"
        "api/user?_format=json"
    )
    
    for endpoint in "${rest_endpoints[@]}"; do
        local response=$(fetch_url "$TARGET/$endpoint")
        
        if echo "$response" | grep -q "name\|display_name\|uid"; then
            if command -v jq &> /dev/null; then
                local username=$(echo "$response" | jq -r '.name // .data[0].attributes.name // .display_name' 2>/dev/null)
                local uid=$(echo "$response" | jq -r '.uid // .data[0].id // .id' 2>/dev/null)
                
                if [ -n "$username" ] && [ "$username" != "null" ]; then
                    found_users["$username"]="$username"
                    user_ids["$username"]="$uid"
                    log "${GREEN}        [+] Found user: ID=$uid | Name='$username' via $endpoint${NC}"
                    ((api_found++))
                fi
            else
                local username=$(echo "$response" | grep -oP '"name":"?\K[^",}]+' | head -1)
                local uid=$(echo "$response" | grep -oP '"uid":"?\K[^",}]+' | head -1)
                
                if [ -n "$username" ]; then
                    found_users["$username"]="$username"
                    user_ids["$username"]="$uid"
                    log "${GREEN}        [+] Found user: ID=$uid | Name='$username'${NC}"
                    ((api_found++))
                fi
            fi
        fi
    done
    
    if [ $api_found -eq 0 ]; then
        log "${YELLOW}        [-] REST API blocked or no users found${NC}"
    else
        log "${GREEN}        [✓] Found $api_found users via REST API${NC}"
    fi
    
    log "${CYAN}[>] [2/8] User Profile Page Enumeration - 1-50${NC}"
    local profile_found=0
    
    for i in {1..50}; do
        if [ $((i % 10)) -eq 0 ]; then
            echo -ne "${BLUE}        [*] Testing ID $i/50...\r${NC}"
        fi
        
        local profile=$(fetch_url "$TARGET/user/$i")
        
        if echo "$profile" | grep -q "member for\|content=\"profile\|user-picture"; then
            local username=$(echo "$profile" | grep -oP '<title>\K[^<|]+' | head -1 | sed 's/ | .*//' | xargs)
            
            if [ -z "$username" ]; then
                username=$(echo "$profile" | grep -oP 'class="username"[^>]*>\K[^<]+' | head -1 | xargs)
            fi
            
            if [ -n "$username" ] && [ -z "${found_users[$username]}" ]; then
                found_users["$username"]="$username"
                user_ids["$username"]="$i"
                log "${GREEN}        [+] Found user: ID=$i | Name='$username' via /user/$i${NC}"
                ((profile_found++))
            fi
        fi
    done
    
    echo -ne "\033[2K\r"
    
    if [ $profile_found -eq 0 ]; then
        log "${YELLOW}        [-] No users found via profile enumeration${NC}"
    else
        log "${GREEN}        [✓] Found $profile_found users via profile pages${NC}"
    fi
    
    log "${CYAN}[>] [3/8] Views User Listing${NC}"
    local views_found=0
    
    local view_paths=("users" "user-list" "members" "people" "authors")
    
    for path in "${view_paths[@]}"; do
        local view_page=$(fetch_url "$TARGET/$path")
        
        if [ -n "$view_page" ]; then
            local usernames=$(echo "$view_page" | grep -oP 'href="/user/[0-9]+"[^>]*>\K[^<]+' | sort -u)
            
            while IFS= read -r username; do
                if [ -n "$username" ] && [ -z "${found_users[$username]}" ]; then
                    found_users["$username"]="$username"
                    log "${GREEN}        [+] Found user from view: '$username'${NC}"
                    ((views_found++))
                fi
            done <<< "$usernames"
        fi
    done
    
    if [ $views_found -eq 0 ]; then
        log "${YELLOW}        [-] No user listing views found${NC}"
    else
        log "${GREEN}        [✓] Found $views_found users from views${NC}"
    fi
    
    log "${CYAN}[>] [4/8] Comment Author Enumeration${NC}"
    local comment_found=0
    
    local homepage=$(fetch_url "$TARGET")
    local comment_authors=$(echo "$homepage" | grep -oP 'class="username"[^>]*>\K[^<]+' | sort -u)
    
    if [ -z "$comment_authors" ]; then
        comment_authors=$(echo "$homepage" | grep -oP 'submitted by.*?<a[^>]*>\K[^<]+' | sort -u)
    fi
    
    while IFS= read -r author; do
        if [ -n "$author" ] && [ -z "${found_users[$author]}" ]; then
            found_users["$author"]="$author"
            log "${GREEN}        [+] Found from comments: '$author'${NC}"
            ((comment_found++))
        fi
    done <<< "$comment_authors"
    
    if [ $comment_found -eq 0 ]; then
        log "${YELLOW}        [-] No users found in comments${NC}"
    else
        log "${GREEN}        [✓] Found $comment_found users from comments${NC}"
    fi
    
    log "${CYAN}[>] [5/8] Content Author Enumeration${NC}"
    local node_found=0
    
    local node_authors=$(echo "$homepage" | grep -oP 'by <a[^>]*>\K[^<]+' | sort -u)
    
    if [ -z "$node_authors" ]; then
        node_authors=$(echo "$homepage" | grep -oP 'author.*?<a[^>]*>\K[^<]+' | sort -u)
    fi
    
    while IFS= read -r author; do
        if [ -n "$author" ] && [ -z "${found_users[$author]}" ]; then
            found_users["$author"]="$author"
            log "${GREEN}        [+] Found content author: '$author'${NC}"
            ((node_found++))
        fi
    done <<< "$node_authors"
    
    if [ $node_found -eq 0 ]; then
        log "${YELLOW}        [-] No content authors found${NC}"
    else
        log "${GREEN}        [✓] Found $node_found content authors${NC}"
    fi
    
    log "${CYAN}[>] [6/8] User Registration Page Analysis${NC}"
    local register_page=$(fetch_url "$TARGET/user/register")
    
    if echo "$register_page" | grep -q "Create new account\|user-register-form"; then
        log "${YELLOW}        [!] User registration is ENABLED${NC}"
        log "${YELLOW}            → Security risk: Anyone can create accounts${NC}"
    else
        log "${GREEN}        [+] User registration appears disabled${NC}"
    fi
    
    log "${CYAN}[>] [7/8] Login Error-Based Enumeration${NC}"
    local login_found=0
    
    local common_users=("admin" "administrator" "root" "user" "test" "demo" "webmaster")
    
    for username in "${common_users[@]}"; do
        if [ -z "${found_users[$username]}" ]; then
            local login_response=$(curl -s -A "$USER_AGENT" --max-time 5 \
                -d "name=$username&pass=wrongpasstest123&form_id=user_login&op=Log+in" \
                "$TARGET/user/login" 2>/dev/null)
            
            if echo "$login_response" | grep -qi "password.*incorrect\|contraseña.*incorrecta\|invalid password"; then
                found_users["$username"]="$username"
                log "${GREEN}        [+] Confirmed via login: '$username' - user exists${NC}"
                ((login_found++))
            fi
        fi
    done
    
    if [ $login_found -eq 0 ]; then
        log "${YELLOW}        [-] No common usernames confirmed${NC}"
    else
        log "${GREEN}        [✓] Confirmed $login_found common usernames${NC}"
    fi
    
    log "${CYAN}[>] [8/8] User Autocomplete Endpoint${NC}"
    local autocomplete_found=0
    
    local ac_queries=("a" "admin" "user")
    
    for query in "${ac_queries[@]}"; do
        local ac_endpoints=(
            "user/autocomplete/$query"
            "admin/people/autocomplete/$query"
        )
        
        for endpoint in "${ac_endpoints[@]}"; do
            local ac_response=$(fetch_url "$TARGET/$endpoint")
            
            if [ -n "$ac_response" ] && echo "$ac_response" | grep -qE '\{.*:.*\}|\[.*\]'; then
                
                if command -v jq &> /dev/null; then
                    local ac_users=$(echo "$ac_response" | jq -r 'if type=="object" then keys[] elif type=="array" then .[] else empty end' 2>/dev/null | grep -v '/' | grep -v '\.' | sort -u)
                else
                    local ac_users=$(echo "$ac_response" | grep -oP '"[^"]+"\s*:' | tr -d '":' | grep -v '/' | grep -v '\.' | sort -u)
                fi
                
                while IFS= read -r username; do
                    if [ -z "$username" ]; then
                        continue
                    fi
                    
                    if [[ "$username" =~ ^(ajaxPageState|basePath|pathPrefix|theme_token|css|js)$ ]]; then
                        continue
                    fi
                    
                    if [[ "$username" =~ \.(css|js|php|html)$ ]] || [[ "$username" =~ \/ ]]; then
                        continue
                    fi
                    
                    if [ ${#username} -lt 2 ]; then
                        continue
                    fi
                    
                    if [ -z "${found_users[$username]}" ]; then
                        found_users["$username"]="$username"
                        log "${GREEN}        [+] Found via autocomplete: '$username'${NC}"
                        ((autocomplete_found++))
                    fi
                done <<< "$ac_users"
                
                if [ $autocomplete_found -gt 0 ]; then
                    break 2
                fi
            fi
        done
    done
    
    if [ $autocomplete_found -eq 0 ]; then
        log "${YELLOW}        [-] Autocomplete endpoint not accessible or no users found${NC}"
    else
        log "${GREEN}        [✓] Found $autocomplete_found users via autocomplete${NC}"
    fi
    
    echo ""
    total_users=${#found_users[@]}
    
    if [ $total_users -gt 0 ]; then
        log "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
        log "${GREEN}║           IDENTIFIED DRUPAL USERS: $total_users                    ${NC}"
        log "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
        log ""
        
        log "${CYAN}┌─────┬──────────────────────────────────────────────────┐${NC}"
        log "${CYAN}│ ID  │ Username                                         │${NC}"
        log "${CYAN}├─────┼──────────────────────────────────────────────────┤${NC}"
        
        for username in "${!found_users[@]}"; do
            local uid="${user_ids[$username]:-?}"
            printf "${CYAN}│${NC} %-3s ${CYAN}│${NC} %-48s ${CYAN}│${NC}\n" "$uid" "${username:0:48}"
        done | sort -t'│' -k2 -n
        
        log "${CYAN}└─────┴──────────────────────────────────────────────────┘${NC}"
        log ""
        
        if [ -n "$OUTPUT_FILE" ]; then
            local userlist_file="${OUTPUT_FILE%.txt}_drupal_users.txt"
            > "$userlist_file"
            for username in "${!found_users[@]}"; do
                echo "$username" >> "$userlist_file"
            done
            log "${GREEN}[✓] Usernames saved to: $userlist_file${NC}"
        fi
        
        log "${YELLOW}[!] SECURITY WARNING:${NC}"
        log "${YELLOW}    → $total_users user(s) enumerated successfully${NC}"
        log "${YELLOW}    → User enumeration is enabled - security risk${NC}"
        log "${YELLOW}    → These accounts could be targeted for attacks${NC}"
    else
        log "${RED}[!] No users could be enumerated${NC}"
        log "${GREEN}[+] User enumeration appears protected${NC}"
    fi
    
    echo ""
}

enumerate_modules() {
    log "${BLUE}[*] Enumerating Drupal Modules${NC}"
    log "${CYAN}[i] Scanning for installed modules...${NC}\n"
    
    local modules_found=0
    declare -A found_modules
    
    log "${CYAN}[>] Method 1: Homepage source analysis${NC}"
    local homepage=$(fetch_url "$TARGET")
    
    local d7_modules=$(echo "$homepage" | grep -oP 'sites/all/modules/\K[^/"\?]+' | sort -u)
    local d8_modules=$(echo "$homepage" | grep -oP 'modules/(?:contrib|custom)/\K[^/"\?]+' | sort -u)
    
    if [ -n "$d7_modules" ]; then
        while IFS= read -r module; do
            if [ -n "$module" ] && [ -z "${found_modules[$module]}" ]; then
                found_modules[$module]=1
                
                local info_file=""
                if [ "$DETECTED_CORE" = "7" ]; then
                    info_file=$(fetch_url "$TARGET/sites/all/modules/$module/$module.info")
                else
                    info_file=$(fetch_url "$TARGET/modules/contrib/$module/$module.info.yml")
                fi
                
                local version=$(echo "$info_file" | grep -oP 'version.*?["\047]\K[0-9].+?(?=["\047])' | head -1)
                
                if [ -n "$version" ]; then
                    log "${GREEN}    [+] ${module} - version ${version}${NC}"
                else
                    log "${GREEN}    [+] ${module} - version unknown${NC}"
                fi
                ((modules_found++))
            fi
        done <<< "$d7_modules"
    fi
    
    if [ -n "$d8_modules" ]; then
        while IFS= read -r module; do
            if [ -n "$module" ] && [ -z "${found_modules[$module]}" ]; then
                found_modules[$module]=1
                
                local info_yml=$(fetch_url "$TARGET/modules/contrib/$module/$module.info.yml")
                local version=$(echo "$info_yml" | grep -oP 'version:\s*["\047]?\K[0-9].+?(?=["\047\s])' | head -1)
                
                if [ -n "$version" ]; then
                    log "${GREEN}    [+] ${module} - version ${version}${NC}"
                else
                    log "${GREEN}    [+] ${module} - version unknown${NC}"
                fi
                ((modules_found++))
            fi
        done <<< "$d8_modules"
    fi
    
    log "${CYAN}[>] Method 2: Checking popular modules${NC}"
    local common_modules=(
        "views"
        "ctools"
        "token"
        "pathauto"
        "admin_menu"
        "jquery_update"
        "libraries"
        "entity"
        "field_group"
        "link"
        "date"
        "webform"
        "imce"
        "captcha"
        "recaptcha"
        "google_analytics"
        "metatag"
        "xmlsitemap"
        "redirect"
        "module_filter"
        "backup_migrate"
        "ckeditor"
        "wysiwyg"
        "media"
        "colorbox"
        "features"
        "strongarm"
        "rules"
        "panels"
        "views_slideshow"
    )
    
    for module in "${common_modules[@]}"; do
        if [ -z "${found_modules[$module]}" ]; then
            local module_paths=(
                "sites/all/modules/$module/$module.info"
                "sites/all/modules/contrib/$module/$module.info"
                "modules/$module/$module.info.yml"
                "modules/contrib/$module/$module.info.yml"
            )
            
            for path in "${module_paths[@]}"; do
                local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/$path")
                
                if [ "$status" = "200" ]; then
                    found_modules[$module]=1
                    log "${GREEN}    [+] ${module} - from directory listing${NC}"
                    ((modules_found++))
                fi
            done <<< "$listed_modules"
        fi
    done
    
    echo ""
    if [ $modules_found -gt 0 ]; then
        log "${GREEN}[✓] Total modules found: $modules_found${NC}"
    else
        log "${YELLOW}[!] No modules could be enumerated${NC}"
    fi
    
    echo ""
}

enumerate_themes() {
    log "${BLUE}[*] Enumerating Drupal Themes${NC}"
    log "${CYAN}[i] Detecting active and installed themes...${NC}\n"
    
    local homepage=$(fetch_url "$TARGET")
    
    log "${CYAN}[>] Method 1: Active theme detection${NC}"
    
    local d7_theme=$(echo "$homepage" | grep -oP 'sites/all/themes/\K[^/"\?]+' | head -1)
    local d8_theme=$(echo "$homepage" | grep -oP 'themes/(?:contrib|custom)/\K[^/"\?]+' | head -1)
    
    local active_theme="${d7_theme:-$d8_theme}"
    
    if [ -n "$active_theme" ]; then
        log "${GREEN}    [+] Active theme: $active_theme${NC}"
        
        local theme_paths=(
            "sites/all/themes/$active_theme/$active_theme.info"
            "themes/$active_theme/$active_theme.info.yml"
            "themes/contrib/$active_theme/$active_theme.info.yml"
        )
        
        for path in "${theme_paths[@]}"; do
            local theme_info=$(fetch_url "$TARGET/$path")
            if [ -n "$theme_info" ]; then
                local version=$(echo "$theme_info" | grep -oP 'version.*?["\047]\K[0-9].+?(?=["\047])' | head -1)
                local name=$(echo "$theme_info" | grep -oP 'name.*?["\047:]\K[^"\047\n]+' | head -1 | xargs)
                
                if [ -n "$name" ]; then
                    log "${GREEN}        Name: $name${NC}"
                fi
                if [ -n "$version" ]; then
                    log "${GREEN}        Version: $version${NC}"
                fi
                break
            fi
        done
    else
        log "${YELLOW}    [-] Could not detect active theme${NC}"
    fi
    
    log "${CYAN}[>] Method 2: Additional installed themes${NC}"
    
    local all_d7_themes=$(echo "$homepage" | grep -oP 'sites/all/themes/\K[^/"\?]+' | sort -u)
    local all_d8_themes=$(echo "$homepage" | grep -oP 'themes/(?:contrib|custom)/\K[^/"\?]+' | sort -u)
    
    local other_found=false
    
    while IFS= read -r theme; do
        if [ "$theme" != "$active_theme" ] && [ -n "$theme" ]; then
            log "${GREEN}    [+] Inactive theme: $theme${NC}"
            other_found=true
        fi
    done <<< "$all_d7_themes"
    
    while IFS= read -r theme; do
        if [ "$theme" != "$active_theme" ] && [ -n "$theme" ]; then
            log "${GREEN}    [+] Inactive theme: $theme${NC}"
            other_found=true
        fi
    done <<< "$all_d8_themes"
    
    if [ "$other_found" = false ]; then
        log "${YELLOW}    [-] No additional themes found${NC}"
    fi
    
    log "${CYAN}[>] Method 3: Default Drupal themes check${NC}"
    
    local default_themes_d7=("bartik" "garland" "seven" "stark")
    local default_themes_d8=("bartik" "seven" "classy" "stable" "stark" "olivero" "umami")
    
    local themes_to_check=()
    if [ "$DETECTED_CORE" = "7" ]; then
        themes_to_check=("${default_themes_d7[@]}")
    else
        themes_to_check=("${default_themes_d8[@]}")
    fi
    
    for theme in "${themes_to_check[@]}"; do
        if [ "$theme" != "$active_theme" ]; then
            local theme_paths=(
                "themes/$theme/$theme.info.yml"
                "core/themes/$theme/$theme.info.yml"
                "sites/all/themes/$theme/$theme.info"
            )
            
            for path in "${theme_paths[@]}"; do
                local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/$path")
                if [ "$status" = "200" ]; then
                    log "${GREEN}    [+] Default theme present: $theme${NC}"
                    break
                fi
            done
        fi
    done
    
    echo ""
}

check_sensitive_files() {
    log "${BLUE}[*] Checking for sensitive files and information disclosure...${NC}"
    
    local exposed_files=()
    
    local files=(
        "CHANGELOG.txt:Info"
        "COPYRIGHT.txt:Info"
        "INSTALL.txt:Info"
        "INSTALL.mysql.txt:Info"
        "INSTALL.pgsql.txt:Info"
        "LICENSE.txt:Info"
        "MAINTAINERS.txt:Info"
        "README.txt:Info"
        "UPGRADE.txt:Info"
        "install.php:High"
        "update.php:High"
        "cron.php:Medium"
        "xmlrpc.php:Medium"
        "authorize.php:Medium"
        "sites/default/settings.php:Critical"
        "sites/default/settings.local.php:Critical"
        "sites/default/default.settings.php:Medium"
        "sites/default/files/backup_migrate/:Critical"
        ".git/config:Critical"
        ".gitignore:Low"
        ".htaccess:Medium"
        "web.config:Medium"
        "composer.json:Info"
        "composer.lock:Info"
        "package.json:Info"
        ".env:Critical"
        "sites/default/files/.htaccess:Low"
        "robots.txt:Info"
        "sites/default/files/backup.sql:Critical"
        "sites/default/files/database.sql:Critical"
        "backup.sql:Critical"
        "dump.sql:Critical"
        "sites/default/files/config/:Medium"
    )
    
    for file_entry in "${files[@]}"; do
        IFS=':' read -r file severity <<< "$file_entry"
        local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/$file")
        
        if [ "$status" = "200" ]; then
            case $severity in
                "Critical")
                    log "${RED}    [!!!] CRITICAL - Exposed: $file${NC}"
                    ;;
                "High")
                    log "${RED}    [!!] HIGH - Exposed: $file${NC}"
                    ;;
                "Medium")
                    log "${YELLOW}    [!] MEDIUM - Exposed: $file${NC}"
                    ;;
                "Low")
                    log "${YELLOW}    [!] LOW - Accessible: $file${NC}"
                    ;;
                "Info")
                    log "${CYAN}    [i] INFO - Public: $file${NC}"
                    ;;
            esac
            exposed_files+=("$file")
        fi
    done
    
    if [ ${#exposed_files[@]} -eq 0 ]; then
        log "${GREEN}    [+] No sensitive files exposed${NC}"
    else
        log ""
        log "${YELLOW}    [!] Total exposed files: ${#exposed_files[@]}${NC}"
    fi
    
    echo ""
}

check_endpoints() {
    log "${BLUE}[*] Checking Drupal endpoints and pages...${NC}"
    
    local endpoints=(
        "user/login:Login Page"
        "user/register:Registration"
        "user/password:Password Reset"
        "admin:Admin Panel"
        "admin/config:Configuration"
        "admin/structure:Structure"
        "admin/content:Content Management"
        "admin/people:User Management"
        "node/add:Content Creation"
        "admin/reports/status:Status Report"
        "admin/modules:Module Management"
        "admin/appearance:Theme Management"
        "install.php:Installer"
        "update.php:Update Script"
        "cron.php:Cron"
        "authorize.php:Authorize"
        "xmlrpc.php:XML-RPC"
        "admin/config/development/performance:Performance"
        "admin/config/people/accounts:Account Settings"
        "filter/tips:Text Format Help"
    )
    
    for endpoint_entry in "${endpoints[@]}"; do
        IFS=':' read -r endpoint name <<< "$endpoint_entry"
        local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/$endpoint")
        
        case $status in
            200)
                log "${GREEN}    [+] $name - $endpoint - HTTP $status${NC}"
                ;;
            403)
                log "${YELLOW}    [!] $name - $endpoint - HTTP $status Forbidden${NC}"
                ;;
            302|301)
                log "${CYAN}    [i] $name - $endpoint - HTTP $status Redirect${NC}"
                ;;
            404)
                log "${CYAN}    [-] $name - $endpoint - HTTP $status Not Found${NC}"
                ;;
            *)
                log "${CYAN}    [?] $name - $endpoint - HTTP $status${NC}"
                ;;
        esac
    done
    
    echo ""
}

check_rest_api() {
    log "${BLUE}[*] Checking REST/JSON API configuration...${NC}"
    
    log "${CYAN}[>] JSON API - Drupal 8+${NC}"
    local jsonapi=$(fetch_url "$TARGET/jsonapi")
    
    if echo "$jsonapi" | grep -q "jsonapi\|data\|links"; then
        log "${YELLOW}    [!] JSON API is ENABLED${NC}"
        
        local node_api=$(fetch_url "$TARGET/jsonapi/node/article")
        if echo "$node_api" | grep -q "data"; then
            log "${YELLOW}        → Article nodes accessible${NC}"
        fi
        
        local user_api=$(fetch_url "$TARGET/jsonapi/user/user")
        if echo "$user_api" | grep -q "data"; then
            log "${RED}        → User data accessible - Security Risk!${NC}"
        fi
    else
        log "${GREEN}    [+] JSON API not accessible${NC}"
    fi
    
    log "${CYAN}[>] REST API${NC}"
    local rest_endpoints=(
        "rest/type/node/article"
        "entity/node"
        "rest/session/token"
        "api"
    )
    
    local rest_found=false
    for endpoint in "${rest_endpoints[@]}"; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/$endpoint")
        if [ "$status" = "200" ] || [ "$status" = "403" ]; then
            log "${YELLOW}    [!] REST endpoint accessible: $endpoint - HTTP $status${NC}"
            rest_found=true
        fi
    done
    
    if [ "$rest_found" = false ]; then
        log "${GREEN}    [+] REST API appears disabled${NC}"
    fi
    
    echo ""
}

check_directory_listing() {
    log "${BLUE}[*] Checking directory listing vulnerabilities...${NC}"
    
    local dirs_exposed=0
    local dirs=(
        "sites/default/files/"
        "sites/all/modules/"
        "sites/all/themes/"
        "modules/"
        "themes/"
        "profiles/"
        "libraries/"
        "core/"
        "misc/"
        "includes/"
    )
    
    for dir in "${dirs[@]}"; do
        local response=$(fetch_url "$TARGET/$dir")
        
        if echo "$response" | grep -qi "Index of"; then
            log "${RED}    [!] Directory listing ENABLED: $dir${NC}"
            ((dirs_exposed++))
        fi
    done
    
    if [ $dirs_exposed -eq 0 ]; then
        log "${GREEN}    [+] No directory listing detected${NC}"
    else
        log "${YELLOW}    [!] Total directories with listing: $dirs_exposed${NC}"
    fi
    
    echo ""
}

scan_vulns() {
    log "${BLUE}[*] Scanning for security misconfigurations...${NC}"
    
    log "${CYAN}[>] User enumeration via /user/N...${NC}"
    local user_test=$(fetch_url "$TARGET/user/1")
    if echo "$user_test" | grep -q "member for\|user-picture"; then
        log "${RED}    [!] User enumeration POSSIBLE${NC}"
    else
        log "${GREEN}    [+] User enumeration appears blocked${NC}"
    fi
    
    log "${CYAN}[>] User registration status...${NC}"
    local register=$(fetch_url "$TARGET/user/register")
    if echo "$register" | grep -q "Create new account\|user-register-form"; then
        log "${YELLOW}    [!] User registration is ENABLED${NC}"
    else
        log "${GREEN}    [+] User registration is disabled${NC}"
    fi
    
    log "${CYAN}[>] Error message disclosure...${NC}"
    local error_test=$(fetch_url "$TARGET/node/999999999")
    if echo "$error_test" | grep -qi "PDOException\|database\|mysql\|postgresql\|sql syntax"; then
        log "${RED}    [!] Database errors exposed - information disclosure${NC}"
    else
        log "${GREEN}    [+] No database errors disclosed${NC}"
    fi
    
    log "${CYAN}[>] Update.php protection...${NC}"
    local update=$(fetch_url "$TARGET/update.php")
    if echo "$update" | grep -q "Drupal database update"; then
        log "${RED}    [!] update.php is ACCESSIBLE - Critical!${NC}"
    else
        log "${GREEN}    [+] update.php is protected${NC}"
    fi
    
    log "${CYAN}[>] Install.php protection...${NC}"
    local install=$(fetch_url "$TARGET/install.php")
    if echo "$install" | grep -q "Select an installation profile\|Choose language"; then
        log "${RED}    [!!!] install.php is ACCESSIBLE - CRITICAL!${NC}"
    else
        log "${GREEN}    [+] install.php is protected${NC}"
    fi
    
    log "${CYAN}[>] Cron.php accessibility...${NC}"
    local cron_status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/cron.php")
    if [ "$cron_status" = "200" ] || [ "$cron_status" = "204" ]; then
        log "${YELLOW}    [!] cron.php is accessible - may allow DoS${NC}"
    else
        log "${GREEN}    [+] cron.php is protected${NC}"
    fi
    
    log "${CYAN}[>] Backup files in public directory...${NC}"
    local backup_dir=$(fetch_url "$TARGET/sites/default/files/backup_migrate/")
    if echo "$backup_dir" | grep -qi "Index of\|\.sql\|\.mysql"; then
        log "${RED}    [!!!] BACKUP FILES EXPOSED - CRITICAL!${NC}"
    else
        local backup_files=("backup.sql" "database.sql" "site.sql" "dump.sql")
        local found_backup=false
        for backup in "${backup_files[@]}"; do
            local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/sites/default/files/$backup")
            if [ "$status" = "200" ]; then
                log "${RED}    [!!!] Backup file exposed: $backup${NC}"
                found_backup=true
            fi
        done
        
        if [ "$found_backup" = false ]; then
            log "${GREEN}    [+] No backup files found${NC}"
        fi
    fi
    
    echo ""
}

check_security_headers() {
    log "${BLUE}[*] Analyzing security headers...${NC}"
    
    local headers=$(curl -s -I -A "$USER_AGENT" "$TARGET" 2>/dev/null)
    
    if echo "$headers" | grep -qi "X-Frame-Options"; then
        local xfo=$(echo "$headers" | grep -i "X-Frame-Options" | cut -d: -f2 | xargs)
        log "${GREEN}    [+] X-Frame-Options: $xfo${NC}"
    else
        log "${YELLOW}    [-] X-Frame-Options: Missing - Clickjacking risk${NC}"
    fi
    
    if echo "$headers" | grep -qi "X-Content-Type-Options"; then
        log "${GREEN}    [+] X-Content-Type-Options: Present${NC}"
    else
        log "${YELLOW}    [-] X-Content-Type-Options: Missing${NC}"
    fi
    
    if echo "$headers" | grep -qi "Content-Security-Policy"; then
        log "${GREEN}    [+] Content-Security-Policy: Present${NC}"
    else
        log "${YELLOW}    [-] Content-Security-Policy: Missing${NC}"
    fi
    
    if echo "$headers" | grep -qi "Strict-Transport-Security"; then
        local hsts=$(echo "$headers" | grep -i "Strict-Transport-Security" | cut -d: -f2 | xargs)
        log "${GREEN}    [+] Strict-Transport-Security: $hsts${NC}"
    else
        log "${YELLOW}    [-] Strict-Transport-Security: Missing${NC}"
    fi
    
    if echo "$headers" | grep -qi "X-Powered-By"; then
        local powered=$(echo "$headers" | grep -i "X-Powered-By" | cut -d: -f2 | xargs)
        log "${YELLOW}    [-] X-Powered-By: Exposed - $powered${NC}"
    else
        log "${GREEN}    [+] X-Powered-By: Hidden${NC}"
    fi
    
    if echo "$headers" | grep -qi "X-Generator"; then
        local gen=$(echo "$headers" | grep -i "X-Generator" | cut -d: -f2 | xargs)
        log "${YELLOW}    [-] X-Generator: Exposed - $gen${NC}"
    else
        log "${GREEN}    [+] X-Generator: Not exposed${NC}"
    fi
    
    if echo "$headers" | grep -qi "^Server:"; then
        local server=$(echo "$headers" | grep -i "^Server:" | cut -d: -f2 | xargs)
        log "${CYAN}    [i] Server: $server${NC}"
    fi
    
    if echo "$headers" | grep -qi "X-Drupal-Cache"; then
        local cache=$(echo "$headers" | grep -i "X-Drupal-Cache" | cut -d: -f2 | xargs)
        log "${CYAN}    [i] X-Drupal-Cache: $cache${NC}"
    fi
    
    if echo "$headers" | grep -qi "X-Drupal-Dynamic-Cache"; then
        local dcache=$(echo "$headers" | grep -i "X-Drupal-Dynamic-Cache" | cut -d: -f2 | xargs)
        log "${CYAN}    [i] X-Drupal-Dynamic-Cache: $dcache${NC}"
    fi
    
    echo ""
}

check_ssl() {
    log "${BLUE}[*] Checking SSL/TLS configuration...${NC}"
    
    if [[ "$TARGET" =~ ^https:// ]]; then
        log "${GREEN}    [+] Site uses HTTPS${NC}"
        
        local homepage=$(fetch_url "$TARGET")
        local http_resources=$(echo "$homepage" | grep -o 'http://[^"]*' | grep -v "http://www.w3.org\|http://schema.org" | head -5)
        
        if [ -n "$http_resources" ]; then
            log "${YELLOW}    [!] Mixed content detected:${NC}"
            echo "$http_resources" | while read -r resource; do
                log "${YELLOW}        • $resource${NC}"
            done
        else
            log "${GREEN}    [+] No mixed content detected${NC}"
        fi
        
        local http_url="${TARGET/https:/http:}"
        local redirect=$(curl -s -I -A "$USER_AGENT" "$http_url" 2>/dev/null | grep -i "location" | head -1)
        
        if echo "$redirect" | grep -q "https://"; then
            log "${GREEN}    [+] HTTP redirects to HTTPS${NC}"
        else
            log "${YELLOW}    [!] HTTP does not redirect to HTTPS${NC}"
        fi
    else
        log "${RED}    [!] Site uses HTTP - unencrypted${NC}"
        log "${YELLOW}    [!] Recommendation: Enable SSL/TLS${NC}"
    fi
    
    echo ""
}

check_known_vulns() {
    log "${BLUE}[*] Checking for known vulnerability indicators...${NC}"
    
    if [ -z "$DETECTED_VERSION" ] && [ -z "$DETECTED_CORE" ]; then
        log "${YELLOW}    [!] Cannot check vulns without version info${NC}"
        echo ""
        return
    fi
    
    local version="${DETECTED_VERSION:-$DETECTED_CORE}"
    
    log "${CYAN}[i] Detected version: $version${NC}"
    log "${CYAN}[i] Checking against known CVEs...${NC}\n"
    
    if [[ "$version" =~ ^7\. ]]; then
        log "${YELLOW}    [!] Drupal 7.x detected - Check for:${NC}"
        log "${YELLOW}        • CVE-2018-7600 - Drupalgeddon2 - RCE${NC}"
        log "${YELLOW}        • CVE-2018-7602 - Drupalgeddon3 - RCE${NC}"
        log "${YELLOW}        • CVE-2014-3704 - Drupalgeddon - SQL Injection${NC}"
        
        local test_response=$(curl -s -A "$USER_AGENT" -X POST \
            -d "form_id=user_pass&_triggering_element_name=name" \
            "$TARGET/?q=user/password" 2>/dev/null)
        
        if echo "$test_response" | grep -q "form_build_id"; then
            log "${RED}        [!] Site may be vulnerable to Drupalgeddon2${NC}"
        fi
    fi
    
    if [[ "$version" =~ ^8\. ]]; then
        log "${YELLOW}    [!] Drupal 8.x detected - Check for:${NC}"
        log "${YELLOW}        • CVE-2018-7600 - if version < 8.5.1${NC}"
        log "${YELLOW}        • CVE-2018-7602 - if version < 8.5.3${NC}"
        log "${YELLOW}        • CVE-2020-13671 - if version < 8.8.8${NC}"
    fi
    
    if [[ "$version" =~ ^9\. ]]; then
        log "${CYAN}    [i] Drupal 9.x - Relatively secure${NC}"
        log "${CYAN}        Check official Drupal security advisories${NC}"
    fi
    
    if [[ "$version" =~ ^10\. ]]; then
        log "${GREEN}    [+] Drupal 10.x - Latest major version${NC}"
        log "${CYAN}        Keep updated with security patches${NC}"
    fi
    
    echo ""
}

check_admin_access() {
    log "${BLUE}[*] Checking admin access points...${NC}"
    
    local admin_paths=(
        "admin"
        "user/login"
        "user"
        "admin/config"
        "admin/structure"
        "admin/content"
        "admin/people"
        "admin/modules"
        "admin/appearance"
        "admin/reports"
    )
    
    for path in "${admin_paths[@]}"; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/$path")
        
        case $status in
            200)
                log "${GREEN}    [+] Accessible: /$path - HTTP $status${NC}"
                ;;
            403)
                log "${YELLOW}    [!] Forbidden: /$path - HTTP $status${NC}"
                ;;
            302|301)
                log "${CYAN}    [i] Redirect: /$path - HTTP $status${NC}"
                ;;
        esac
    done
    
    echo ""
}

check_files_directory() {
    log "${BLUE}[*] Checking files directory security...${NC}"
    
    local files_dir=$(fetch_url "$TARGET/sites/default/files/")
    
    if echo "$files_dir" | grep -qi "Index of"; then
        log "${RED}    [!] Files directory listing ENABLED${NC}"
        log "${RED}        → All uploaded files can be enumerated!${NC}"
    else
        log "${GREEN}    [+] Files directory listing disabled${NC}"
    fi
    
    local htaccess_status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$TARGET/sites/default/files/.htaccess")
    if [ "$htaccess_status" = "200" ] || [ "$htaccess_status" = "403" ]; then
        log "${GREEN}    [+] .htaccess present in files directory${NC}"
    else
        log "${YELLOW}    [!] .htaccess missing in files directory${NC}"
    fi
    
    log "${CYAN}[>] Testing PHP execution in files directory...${NC}"
    local test_file="test_$(date +%s).php"
    local php_test=$(curl -s -A "$USER_AGENT" "$TARGET/sites/default/files/$test_file" 2>/dev/null)
    
    if echo "$php_test" | grep -q "<?php"; then
        log "${RED}    [!!!] PHP execution may be enabled in files directory!${NC}"
    else
        log "${GREEN}    [+] PHP execution appears blocked${NC}"
    fi
    
    echo ""
}

generate_summary() {
    log "${MAGENTA}"
    log "╔═══════════════════════════════════════════════════════════╗"
    log "║                    ENUMERATION SUMMARY                    ║"
    log "╚═══════════════════════════════════════════════════════════╝"
    log "${NC}"
    
    log "${CYAN}[+] Target: $TARGET${NC}"
    
    if [ -n "$DETECTED_VERSION" ]; then
        log "${CYAN}[+] Drupal Version: $DETECTED_VERSION${NC}"
    elif [ -n "$DETECTED_CORE" ]; then
        log "${CYAN}[+] Drupal Core: $DETECTED_CORE${NC}"
    else
        log "${YELLOW}[!] Version: Unknown${NC}"
    fi
    
    log ""
    log "${BLUE}[*] Scan completed at: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    
    if [ -n "$OUTPUT_FILE" ]; then
        log "${GREEN}[✓] Full report saved to: $OUTPUT_FILE${NC}"
    fi
    
    log ""
    log "${YELLOW}[!] RECOMMENDATIONS:${NC}"
    log "${YELLOW}    1. Review all identified users and disable unused accounts${NC}"
    log "${YELLOW}    2. Ensure update.php and install.php are protected${NC}"
    log "${YELLOW}    3. Disable directory listing on all directories${NC}"
    log "${YELLOW}    4. Keep Drupal core and all modules updated${NC}"
    log "${YELLOW}    5. Implement strong security headers${NC}"
    log "${YELLOW}    6. Use HTTPS with proper TLS configuration${NC}"
    log "${YELLOW}    7. Disable user enumeration if possible${NC}"
    log "${YELLOW}    8. Review and secure REST/JSON API endpoints${NC}"
    
    echo ""
}

main() {
    if [ $# -lt 1 ]; then
        banner
        echo -e "${RED}[!] Usage: $0 <target_url> [output_file]${NC}"
        echo -e "${CYAN}[*] Example: $0 https://example.com report.txt${NC}"
        echo ""
        exit 1
    fi
    
TARGET="$1"
OUTPUT_FILE="${2:-}"

# Validar que el nombre del archivo solo tenga caracteres seguros
if [ -n "$OUTPUT_FILE" ]; then
    if [[ "$OUTPUT_FILE" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        > "$OUTPUT_FILE"
        echo "Drupal Enumeration Report" >> "$OUTPUT_FILE"
        echo "Target: $TARGET" >> "$OUTPUT_FILE"
        echo "Date: $(date)" >> "$OUTPUT_FILE"
        echo "========================================" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        echo -e "${RED}[!] Invalid output file name: $OUTPUT_FILE. Skipping file creation.${NC}"
        OUTPUT_FILE=""
    fi
fi
    
    banner
    
    check_deps
    validate_url "$TARGET"
    
    log "${GREEN}[*] Starting Drupal enumeration...${NC}"
    log "${CYAN}[*] Target: $TARGET${NC}"
    echo ""
    
    if ! check_drupal; then
        log "${RED}[!] Target does not appear to be a Drupal site${NC}"
        log "${YELLOW}[!] Proceeding anyway with enumeration...${NC}"
        echo ""
    fi
    
    detect_version
    
    log "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║              STARTING DETAILED ENUMERATION                ║${NC}"
    log "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    enumerate_users
    enumerate_modules
    enumerate_themes
    
    log "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║                 SECURITY ANALYSIS                         ║${NC}"
    log "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_sensitive_files
    check_endpoints
    check_rest_api
    check_directory_listing
    scan_vulns
    check_security_headers
    check_ssl
    check_known_vulns
    check_admin_access
    check_files_directory
    
    generate_summary
    
    log "${GREEN}[✓] Enumeration completed successfully!${NC}"
    echo ""
}

# Execute main function with all arguments
main "$@"

# Enumerate modules in directories
enumerate_modules() {
    log "${CYAN}[>] Method 1: Checking enabled modules from Drupal system${NC}"
    local enabled_modules=$(fetch_url "$TARGET/?q=admin/modules")
    
    if echo "$enabled_modules" | grep -q "Module list"; then
        log "${GREEN}    [+] Retrieved enabled modules from admin/modules${NC}"
        # Aquí podrías parsear más info si quieres
    else
        log "${YELLOW}    [-] Could not retrieve module list from admin/modules${NC}"
    fi

    log "${CYAN}[>] Method 2: Checking modules via known paths${NC}"
    local common_modules=("views" "path" "token" "ctools" "admin_toolbar" "devel")
    
    for module in "${common_modules[@]}"; do
        local module_path="$TARGET/modules/$module"
        local status=$(curl -s -o /dev/null -w "%{http_code}" -A "$USER_AGENT" "$module_path")
        if [ "$status" = "200" ]; then
            log "${GREEN}    [+] $module - common module${NC}"
        fi
    done

    log "${CYAN}[>] Method 3: Module directory enumeration${NC}"
    local module_dirs=("sites/all/modules/" "modules/contrib/" "modules/custom/")
    
    for dir in "${module_dirs[@]}"; do
        local dir_list=$(fetch_url "$TARGET/$dir")
        
        if echo "$dir_list" | grep -q "Index of"; then
            log "${YELLOW}    [!] Directory listing ENABLED: $dir${NC}"
            local listed_modules=$(echo "$dir_list" | grep -oP 'href="[^"]*/"' | grep -v "Parent" | cut -d'"' -f2 | tr -d '/')
            
            while IFS= read -r module; do
                if [ -n "$module" ] && [ -z "${found_modules[$module]}" ]; then
                    found_modules[$module]=1
                    log "${GREEN}    [+] Module found: $module - common module${NC}"
                    ((modules_found++))
                fi
            done <<< "$listed_modules"
        fi
    done
}
# Footer / disclaimer
# Footer / disclaimer
log "\n${PURPLE}═══════════════════════════════════════════${NC}"
log "${RED}⚠  Authorized testing only${NC}"
log "${PURPLE}   github.com/pistacha-git | @pistacha-git${NC}"
log "${PURPLE}═══════════════════════════════════════════${NC}"
# Exit with success
exit 0
