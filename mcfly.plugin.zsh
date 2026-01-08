# -*- mode: sh; eval: (sh-set-shell "zsh") -*-
#
# Plugin Name: mcfly
# Description: Plugin to integrate the `mcfly` command history tool.
# Repository: https://github.com/johnstonskj/zsh-mcfly-plugin
#
# Public variables:
#
# * `MCFLY`; plugin-defined global associative array with the following keys:
#   * `_ALIASES`; a list of all aliases defined by the plugin.
#   * `_FUNCTIONS`; a list of all functions defined by the plugin.
#   * `_PLUGIN_DIR`; the directory the plugin is sourced from.
#

############################################################################
# Standard Setup Behavior
############################################################################

# See https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# See https://wiki.zshell.dev/community/zsh_plugin_standard#standard-plugins-hash
declare -gA MCFLY
MCFLY[_PLUGIN_DIR]="${0:h}"
MCFLY[_ALIASES]=""
MCFLY[_FUNCTIONS]=""

############################################################################
# Internal Support Functions
############################################################################

#
# This function will add to the `MCFLY[_FUNCTIONS]` list which is
# used at unload time to `unfunction` plugin-defined functions.
#
# See https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
# See https://wiki.zshell.dev/community/zsh_plugin_standard#the-proposed-function-name-prefixes
#
.mcfly_remember_fn() {
    builtin emulate -L zsh

    local fn_name="${1}"
    if [[ -z "${MCFLY[_FUNCTIONS]}" ]]; then
        MCFLY[_FUNCTIONS]="${fn_name}"
    elif [[ ",${MCFLY[_FUNCTIONS]}," != *",${fn_name},"* ]]; then
        MCFLY[_FUNCTIONS]="${MCFLY[_FUNCTIONS]},${fn_name}"
    fi
}
.mcfly_remember_fn .mcfly_remember_fn

.mcfly_define_alias() {
    local alias_name="${1}"
    local alias_value="${2}"

    alias ${alias_name}=${alias_value}

    if [[ -z "${MCFLY[_ALIASES]}" ]]; then
        MCFLY[_ALIASES]="${alias_name}"
    elif [[ ",${MCFLY[_ALIASES]}," != *",${alias_name},"* ]]; then
        MCFLY[_ALIASES]="${MCFLY[_ALIASES]},${alias_name}"
    fi
}
.mcfly_remember_fn .mcfly_remember_alias

############################################################################
# Plugin Unload Function
############################################################################

# See https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
mcfly_plugin_unload() {
    builtin emulate -L zsh

    # Remove all remembered functions.
    local plugin_fns
    IFS=',' read -r -A plugin_fns <<< "${MCFLY[_FUNCTIONS]}"
    local fn
    for fn in ${plugin_fns[@]}; do
        whence -w "${fn}" &> /dev/null && unfunction "${fn}"
    done
    
    # Remove all remembered aliases.
    local aliases
    IFS=',' read -r -A aliases <<< "${MCFLY[_ALIASES]}"
    local alias
    for alias in ${aliases[@]}; do
        unalias "${alias}"
    done
    
    # Remove the global data variable.
    unset MCFLY

    # Remove this function.
    unfunction mcfly_plugin_unload
}

############################################################################
# Initialize Plugin
############################################################################

eval $(mcfly init zsh)

true
