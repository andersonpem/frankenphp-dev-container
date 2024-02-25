#!/usr/bin/env python3
import signal
import subprocess

import yaml
from yaml.representer import SafeRepresenter
from collections import OrderedDict
import sys

from prompt_toolkit import prompt
from prompt_toolkit.completion import WordCompleter

global yes_no_completer
yes_no_completer = WordCompleter(['yes', 'no'], ignore_case=True)


# Define the signal handler function
def signal_handler(sig, frame):
    print('\nYou pressed Ctrl+C! Exiting gracefully...')
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)


def ordered_dict_representer(dumper, data):
    return dumper.represent_mapping('tag:yaml.org,2002:map', data.items())


yaml.add_representer(OrderedDict, ordered_dict_representer)


def get_user_input():
    has_project = input("Do you have a PHP project in the current folder or a sub-folder? (yes/no): ").strip().lower()
    folder_name = "."

    if has_project == "yes":
        confirm_root = input("Is it in the root folder? (yes/no): ").strip().lower()
        if confirm_root != "yes":
            folder_name = input("Enter the folder name of the project: ").strip()
            if folder_name:
                folder_name = f"./{folder_name}"
    else:
        create_project = input("Do you want to create a new PHP project? (yes/no): ").strip().lower()
        if create_project == "yes":
            project_details = create_composer_project()
            folder_name = project_details['folder_name']
        else:
            folder_name = input("Enter the folder name for the project: ").strip()
            if folder_name:
                folder_name = f"./{folder_name}"

    db_choice = ""
    while db_choice.lower() not in ["pg", "mysql", "none"]:
        db_choice = input("Do you want a database? (PG/MySQL/None) [MySQL]:  ").strip()
        if not db_choice:
            db_choice = "mysql"

    db_root_password = db_user = db_user_password = db_port = redis_port = ""
    if db_choice.lower() in ["pg", "mysql"]:
        db_root_password = input("Enter the root password for the database [root]: ").strip()
        if not db_root_password:
            db_root_password = "root"
        db_user = input("Enter the username for the database [homestead]: ").strip()
        if not db_user:
            db_user = "homestead"
        db_user_password = input("Enter the password for the database user [password]: ").strip()
        if not db_user_password:
            db_user_password = "password"
        db_port = input("Enter the port for the database: ").strip()

    want_redis = input("Do you want to use Redis? (yes/no): [no] ").strip().lower()
    if want_redis in ["y", "yes"]:
        want_redis = "yes"
    else:
        want_redis = "no"

    redis_port = "6379"
    if want_redis and want_redis == "yes":
        redis_port = input("Enter the port for Redis: ").strip()

    return db_choice.lower(), db_root_password, db_user, db_user_password, db_port, want_redis, redis_port


def create_composer_project():
    print("=============================================================================================")
    composer_completer = WordCompleter(['symfony/skeleton', 'laravel/laravel'], ignore_case=True)
    print("Please specify a composer project you want to create. \nExample: laravel/laravel, symfony/skeleton.\n[You "
          "can use tab to autocomplete].")
    composer_project = prompt(
        "Your choice: ",
        completer=composer_completer)
    print("You chosen: ", composer_project)
    project_version = input("Inform the version. Ex: 7.0: ").strip()
    if not project_version == "":
        project_version = project_version + '.*'  # semver
    install_in_root = input("Install in the root folder? (yes/no): ").strip().lower()
    if install_in_root == "yes":
        folder_name = "."
    else:
        folder_name = input("Inform the folder name: ").strip()
        if folder_name:
            folder_name = f"./{folder_name}"
        else:
            folder_name = "."

    # Adjust the Docker command according to the project details
    docker_command = [
        "docker", "run", "--rm", "--interactive", "--tty",
        "--volume", f"{folder_name}:/app",
        "composer", "create-project", f"{composer_project}:{project_version}",
        folder_name if folder_name != "." else "/app"
    ]

    # Execute the Docker command
    try:
        print("Running Docker command to create the Composer project...")
        subprocess.run(docker_command, check=True)
        print("Composer project created successfully.")
        print("\033c")
    except subprocess.CalledProcessError as e:
        print(f"Failed to create Composer project: {e}")
        print("Please correct any issues and try again. Exiting...")
        sys.exit(1)

    return {"folder_name": folder_name}


def build_docker_compose(db_choice, db_root_password, db_user, db_user_password, db_port, want_redis, redis_port):
    docker_compose = OrderedDict()
    docker_compose["version"] = "3.9"
    docker_compose["services"] = {}
    docker_compose["volumes"] = {}

    if db_choice == "mysql":
        mysql_service = OrderedDict()
        mysql_service["image"] = "mysql:8.0"
        mysql_service["environment"] = {
            "MYSQL_ROOT_PASSWORD": "${MYSQL_ROOT_PASSWORD}",
            "MYSQL_DATABASE": "${MYSQL_DATABASE}",
            "MYSQL_USER": "${MYSQL_USER}",
            "MYSQL_PASSWORD": "${MYSQL_PASSWORD}"
        }
        mysql_service["ports"] = ["${MYSQL_PORT:-3307}:3306"]
        mysql_service["volumes"] = ["mysql_data:/var/lib/mysql"]
        docker_compose["services"]["mysql"] = mysql_service
        docker_compose["volumes"]["mysql_data"] = {"driver": "local"}

    elif db_choice == "pg":
        postgres_service = OrderedDict()
        postgres_service["image"] = "postgres"
        postgres_service["environment"] = {
            "POSTGRES_DB": "${POSTGRES_DB}",
            "POSTGRES_USER": "${POSTGRES_USER}",
            "POSTGRES_PASSWORD": "${POSTGRES_PASSWORD}"
        }
        postgres_service["ports"] = ["${POSTGRES_PORT:-5432}:5432"]
        postgres_service["volumes"] = ["postgres_data:/var/lib/postgresql/data"]
        docker_compose["services"]["postgres"] = postgres_service
        docker_compose["volumes"]["postgres_data"] = {"driver": "local"}

    if want_redis == "yes":
        redis_service = OrderedDict()
        redis_service["image"] = "redis"
        redis_service["ports"] = ["${REDIS_PORT:-6379}:6379"]
        redis_service["volumes"] = ["redis-data:/data:rw"]
        docker_compose["services"]["redis"] = redis_service
        docker_compose["volumes"]["redis-data"] = {"driver": "local"}

    return docker_compose


def generate_env_file(db_choice, db_root_password, db_user, db_user_password, db_port, want_redis, redis_port):
    env_content = ""
    if db_choice == "mysql":
        env_content += f"""
MYSQL_ROOT_PASSWORD={db_root_password}
MYSQL_DATABASE=homestead
MYSQL_USER={db_user}
MYSQL_PASSWORD={db_user_password}
MYSQL_PORT={db_port}
        """.strip()
    elif db_choice == "pg":
        env_content += f"""
POSTGRES_DB=homestead
POSTGRES_USER={db_user}
POSTGRES_PASSWORD={db_user_password}
POSTGRES_PORT={db_port}
        """.strip()
    if want_redis == "yes":
        env_content += f"\nREDIS_PORT={redis_port}"
    return env_content


def write_files(docker_compose, env_content):
    with open("docker-compose.yml", "w") as file:
        yaml.dump(docker_compose, file)

    with open(".env", "w") as file:
        file.write(env_content)


def main():
    print("=============================================================================================")
    print("            Welcome to Canvas! The TuskWhale FrankenPHP Docker Compose Generator")
    print("=============================================================================================")

    db_choice, db_root_password, db_user, db_user_password, db_port, want_redis, redis_port = get_user_input()
    docker_compose = build_docker_compose(db_choice, db_root_password, db_user, db_user_password, db_port, want_redis,
                                          redis_port)

    env_content = generate_env_file(db_choice, db_root_password, db_user, db_user_password, db_port, want_redis,
                                    redis_port)
    write_files(docker_compose, env_content)
    print("Docker Compose and .env files have been generated.")


if __name__ == "__main__":
    main()
