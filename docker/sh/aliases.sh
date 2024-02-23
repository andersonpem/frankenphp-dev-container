alias bcs="php bin/console"
alias cda="composer dump-autoload"
alias dumpvars="composer dump-env $APP_ENV"
alias cachereset="bin/console doctrine:cache:clear-metadata && bin/console doctrine:cache:clear-query && bin/console doctrine:cache:clear-result && bin/console app:cache:clear && sudo rm -Rf $PROJECT_ROOT/var/cache/*"
alias phpunit="php bin/phpunit"
aliases_help() {
    echo -e "${cl_info}Helper aliases:${cl_reset}"
    echo -e "${cl_success}bcs${cl_reset} 'php bin/console' - Runs a PHP command within the bin/console directory."
    echo -e "${cl_success}cda${cl_reset} 'composer dump-autoload' - Dumps the autoloader using Composer."
    echo -e "${cl_success}cda${cl_reset} 'composer dump-env \$APP_ENV' - Dumps the environment variables set for the application."
    echo -e "${cl_success}cachereset${cl_reset} 'bin/console cache:reset' - Resets all the cache using a console command."
}