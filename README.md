ldapm
====================

[![license](https://img.shields.io/github/license/ralish/bash-script-template)](https://choosealicense.com/licenses/mit/)

A *Bash* script to create and migrate LDAP structure.

- [ldapm](#ldapm)
  - [Motivation](#motivation)
  - [Building](#building)
  - [Usage](#usage)
  - [License](#license)

Motivation
----------

Managing LDAP structure isn't that hard, but only the guy who have done it know how it works and how to restore it. This script is a simple way to manage LDAP structure and restore it, and should help you to manage your LDAP structure and simplify local development.

Building
--------

In order to generate the ldapm script, you need to run the following command:

```bash
./build.sh
```

Usage
-----

This script need to have a local folder `migrations` that contains all the migration files. The migration files should be named with the following pattern:

```
xxxxxx-description.ldif
```

Where `xxxxxx` is a number that represents the migration order and `description` is a description of the migration. The migration files should be valid LDIF files.

Running the script will apply all the migrations that haven't been applied yet. The script will create a `.ldapm` file in the root of the project to keep track of the applied migrations.

To run the script, you need to run the following command:

```bash
./ldapm
```

To create a new migration, you can run the following command:

```bash
./ldapm create "description"
```

This will create a new migration file in the `migrations` folder, using the next available number.

License
-------

All content is licensed under the terms of [The MIT License](LICENSE).
