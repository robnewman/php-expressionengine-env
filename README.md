php-expressionengine-env Cookbook
=================================
Chef recipe for sanely building a VM that runs a LAMP stack with
the Ellis Labs Expression Engine PHP framework for IRIS VMs
and websites.

Requirements
------------
Needs a basic Ubuntu/RHEL flavor VM. Works on RHEL 6.5 (PVHVM)

Attributes
----------
* ipv4_address
* ipv6_address
* db_username
* db_password
* vm_name
* server_name
* ee_source
* vhostsdir
* iris_path
* iris_server_admin
* iris_customlog_path
* iris_customlog_format
* iris_errorlog_path

Usage
-----
Include `php-expressionengine-env` in your node's `run_list` in
addition to `apt` and `user::data_bag`.

```json
{
  "name":"PHPExpressionEngineEnv",
  "run_list": [
    "recipe[apt]",
    "recipe[php-expression-engine-env]",
    "recipe[user::data_bag]",
  ]
}
```

Further Reading
---------------

* ExpressionEngine website: http://ellislab.com/expressionengine
* Their installation guide: http://ellislab.com/expressionengine/user-guide/installation/installation.html
* Their best practices: http://ellislab.com/expressionengine/user-guide/installation/best_practices.html

Contributing
------------
Don't contribute just yet - this is purely for Rackspace DevOps to
see if it can be integrated into their managed VM DevOps env.

License and Authors
-------------------
* Rob Newman <robertlnewman@gmail.com>
