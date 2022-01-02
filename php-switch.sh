#!/usr/bin/env zsh

# Retrieve all PHP versions installed via homebrew
function getInstalledPHPVersions() {
    brew ls --versions \
        | grep -E 'php(@.*)?\s' \
        | grep -o '\s\d\.\d' \
        | sed 's/^[[:space:]]*//' \
        | uniq \
        | sort
}

function init() {
    # Collect all installed PHP version in an array
    installedPHPVersions=($(getInstalledPHPVersions))
    # Dynamically generate alias functions
    for version in ${installedPHPVersions[*]}; do
        eval "$version() { runOrSwitch $version \"\$@\"; }"
    done
}

function currentPHPVersion() {
    php -r '$version=explode(".", PHP_VERSION); printf("%s.%s", $version[0], $version[1]);'
}

# Switches the current PHP for the selected one
function switchToPHP() {
    local newVersion=$1
    local currentVersion="$(currentPHPVersion)"

    # Skip if switching to same version
    if [ "$newVersion" = "$currentVersion" ]; then
        php -v
        return
    fi

    # Unlink current PHP version
    brew unlink "php@$currentVersion" &> /dev/null

    # Link new version and print it
    brew link --overwrite --force "php@$newVersion" &> /dev/null
    php -v
}

# Run a specific version of PHP
function runAsPHP() {
    setopt local_options nullglob
    stable=(/usr/local/Cellar/php/*/bin/php)
    other=(/usr/local/Cellar/php@"$1"/*/bin/php)
    shift
    if [[ -f "${other[1]}" ]]; then
        ${other[1]} "$@"
    elif [[ -f "${stable[1]}" ]]; then
        ${stable[1]} "$@"
    else
        echo "PHP $1 does not appear to be installed."
    fi
}

# Switches to the specified PHP versions if there are no
# additional arguments or runs the command using the PHP
# versions if there are some arguments.
function runOrSwitch() {
    version=$1
    shift
    if [ $# -eq 0 ]; then
        switchToPHP "$version"
    else
        runAsPHP "$version" "$@"
    fi
}

init
