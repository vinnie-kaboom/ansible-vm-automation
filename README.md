# gad-infra-ansible: GPC DSCADA Infrastructure Automation with Ansible

Welcome to the `gad-infra-ansible` repository! This repository contains our Ansible playbooks and roles for automating the provisioning, configuration, and management of our infrastructure. Ansible is a powerful automation engine that simplifies complex IT tasks, and this repository is structured to make our automation efforts organized, maintainable, and scalable.

This document provides an overview of the repository structure and outlines the best practices we follow to ensure consistency and clarity in our Ansible automation. Whether you're new to Ansible or an experienced user, this guide will help you understand how our automation is organized. 

*(Some server names, groups and functions in this README are made up for example and education's sake, but the structure/architecture of the directory and functions of Ansible are true and what GPC DSCADA is aiming for. We will update this with real server names, groups, and functions as this repo is filled with viable code/infrastructure.)*

## Repository Structure

The repository is organized into several key directories, each serving a specific purpose:

gad-infra-ansible/
├── inventory/
│   ├── hosts.yaml              # Defines target hosts and groups
│   ├── group_vars/             # Contains variables specific to groups
│   │   ├── webservers.yml
│   │   ├── database.yml
│   │   └── ...
│   ├── host_vars/              # Contains variables specific to individual hosts
│   │   ├── server1.yml
│   │   ├── server2.yml
│   │   └── ...
├── playbooks/
│   ├── site.yml                # Main entry point for playbooks
│   ├── webservers/             # Playbooks for webserver management
│   │   ├── deploy.yml
│   │   ├── configure.yml
│   │   └── ...
│   ├── database/               # Playbooks for database management
│   │   ├── setup.yml
│   │   ├── backup.yml
│   │   └── ...
│   ├── network/                # Playbooks for network device configuration
│   │   ├── configure_switches.yml
│   │   ├── configure_routers.yml
│   │   └── ...
│   ├── security/               # Playbooks for security hardening
│   │   ├── harden_servers.yml
│   │   ├── install_firewall.yml
│   │   └── ...
│   ├── common/                 # Playbooks for common system tasks
│   │   ├── install_packages.yml
│   │   ├── configure_users.yml
│   │   └── ...
├── roles/
│   ├── common_all/
│   │   ├── defaults/
│   │   │   └── main.yml        # Default variables for the role (lowest priority)
│   │   ├── vars/
│   │   │   └── main.yml        # Specific variables for the role
│   │   ├── tasks/
│   │   │   └── main.yml        # Main tasks performed by the role
│   │   ├── handlers/
│   │   │   └── main.yml        # Handlers for the role (actions triggered by notifications)
│   │   ├── meta/
│   │   │   └── main.yml        # Role metadata (author, dependencies, etc.)
│   │   ├── templates/
│   │   │   ├── nginx.conf.j2
│   │   │   └── httpd.conf.j2
│   │   └── files/
│   │       ├── index.html      # Static files used by the role
│   │       └── logo.png
│   ├── database_server/
│   │   └── ... (same structure as common_all but configure specifically for database role)
│   ├── webserver/
│   │   └── ...
│   └── ... (other roles)
├── global_vars/                # Global variables
│   ├── subnet_config.yml       # Network variables for DSCADA subnets
│   └── ...
├── library/                    # Custom Ansible modules
│   └── my_custom_module.py
└── README.md

### `inventory/`

This directory contains information about the target systems Ansible will manage.

* **`hosts.yaml`**: This is our static inventory file. It lists all the managed hosts, organized into logical groups. Groups allow us to apply configurations to multiple servers simultaneously. For example, you might have groups like `webservers`, `database_servers`, etc.
* **`group_vars/`**: This directory holds YAML files containing variables that are specific to groups defined in the `hosts.yaml` file. For instance, `webservers.yml` might contain variables like the default web server port or the packages to install on all web servers.
* **`host_vars/`**: Similar to `group_vars/`, but this directory contains YAML files with variables specific to individual hosts. For example, `server1.yml` might define a unique IP address or specific settings for that particular server.

### `playbooks/`

Playbooks are the heart of Ansible automation. They are YAML files that define a set of tasks to be executed on the target hosts.

* **`site.yml`**: This is typically the main playbook that orchestrates the execution of other, more specific playbooks. It acts as the entry point for our primary automation workflows.
* **Subdirectories (e.g., `webservers/`, `database/`, `network/`, `security/`, `common/`)**: These directories organize playbooks based on the functionality they manage. This modular approach makes it easier to find and run specific automation tasks.
    * For example, the `webservers/` directory contains playbooks like `deploy.yml` (to deploy web applications) and `configure.yml` (to set up web server configurations).
    * The `common/` directory houses playbooks for tasks that are applicable across different types of servers, such as installing base packages or managing user accounts.

### `roles/`

Roles are a fundamental concept in Ansible that promote the organization, modularity, and reusability of automation code by packaging related components like tasks, variables, handlers, templates, and static files into a structured directory. Playbooks then orchestrate the execution of these roles, calling upon them to perform specific functions on targeted hosts. This allows playbooks to remain concise and focused on the overall automation workflow, delegating the detailed implementation to the well-defined roles.

* **Subdirectories (e.g., `common_all/`, `database_server/`, `webserver/`)**: Each subdirectory represents a specific role. The name of the role usually indicates the functionality it provides (e.g., `webserver` configures a web server).
* **Role Structure**: Inside each role directory, you'll find a standard structure:
    * **`defaults/main.yml`**: Contains default variables for the role. These have the lowest precedence and can be overridden by other variable sources.
    * **`vars/main.yml`**: Contains more specific variables for the role. These have a higher precedence than default variables.
    * **`tasks/main.yml`**: This is the main file containing the sequence of tasks that the role will execute. Tasks can be broken down into smaller, more manageable files if needed.
    * **`handlers/main.yml`**: Contains handlers, which are special tasks that are executed only when notified by another task. They are often used for service management (e.g., restarting a service after a configuration change).
    * **`meta/main.yml`**: Contains metadata about the role, such as the author, license, and dependencies on other roles.
    * **`templates/`**: This directory holds Jinja2 template files, which allow for dynamic generation of configuration files based on variables.
    * **`files/`**: This directory contains static files that can be copied to the managed hosts.

### `global_vars/`

This directory is used to store variables that are intended for global use across multiple playbooks and roles.

* `subnet_config.yml`: This specific file likely contains variables related to our network and infrastructure configuration for different subnets within our DSCADA environment. This helps centralize important environment-specific settings.

### `library/`

This optional directory can contain custom Ansible modules or community-developed modules that extend Ansible's built-in functionality. Modules are the building blocks of Ansible tasks, performing actions on managed hosts.

## Best Practices

To ensure our Ansible automation remains effective and easy to manage, we adhere to the following best practices:

1.  **Keep it Modular:** We strive to break down complex automation into reusable roles and specific playbooks. This promotes code reuse and makes it easier to understand and maintain individual components.
2.  **Use Variables Effectively:** We leverage `global_vars/`, `group_vars/`, `host_vars/`, and role variables (`defaults/` and `vars/`) to manage configuration data. This keeps playbooks and tasks generic and adaptable to different environments.
3.  **Follow Role Structure:** We consistently adhere to the standard Ansible role directory structure. This makes it easier for team members (and the Ansible community) to understand the purpose and contents of each role.
4.  **Clear Naming Conventions:** We use descriptive and consistent naming for inventory groups, hosts, variables, playbooks, and roles. This improves readability and reduces ambiguity.
5.  **Idempotency:** We aim for our playbooks and roles to be idempotent, meaning they can be run multiple times without causing unintended changes. Ansible modules are generally designed to be idempotent.
6.  **Documentation:** We strive to document our playbooks, roles, and any custom modules. This README file is a starting point, and we encourage adding comments within the Ansible code itself to explain complex logic.
7.  **Version Control:** All changes to this repository are managed using Git. We follow standard Git workflows (e.g., using branches, pull requests) to ensure code quality and facilitate collaboration.
8.  **Testing:** While not explicitly in the structure, we aim to eventually incorporate testing frameworks to automatically test our roles and playbooks.

## Happy automating!
