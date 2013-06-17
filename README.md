Description
===========

Installs and configures Couchbase.

Requirements
============

Chef 0.10.10 and Ohai 0.6.12 are required due to the use of platform_family.

Platforms
---------

* Debian family (Debian, Ubuntu etc)
* Red Hat family (Redhat, CentOS, Oracle etc)
* Microsoft Windows

Note that Couchbase Server does not support Windows 8 or Server 2012: see http://www.couchbase.com/issues/browse/MB-6395. This is targeted to be fixed in Couchbase 2.1.

Attributes
==========

couchbase-server
----------------

* `node['couchbase']['server']['edition']`          - The edition of couchbase-server to install, "community" or "enterprise"
* `node['couchbase']['server']['version']`          - The version of couchbase-server to install
* `node['couchbase']['server']['package_file']`     - The couchbase-server package file to download and install
* `node['couchbase']['server']['package_base_url']` - The url path to download the couchbase-server package file from
* `node['couchbase']['server']['package_full_url']` - The full url to the couchbase-server package file to download and install
* `node['couchbase']['server']['database_path']`    - The directory Couchbase should persist data to
* `node['couchbase']['server']['log_dir']`          - The directory Couchbase should log to
* `node['couchbase']['server']['memory_quota_mb']`  - The per server RAM quota for the entire cluster in megabytes
                                                      defaults to Couchbase's maximum allowed value
* `node['couchbase']['server']['username']`         - The cluster's username for the REST API and Admin UI
* `node['couchbase']['server']['password']`         - The cluster's password for the REST API and Admin UI

client
------

* `node['couchbase']['client']['version']`          - The version of libcouchbase to install

moxi
----

* `node['couchbase']['moxi']['version']`            - The version of moxi to install
* `node['couchbase']['moxi']['package_file']`       - The package file to download
* `node['couchbase']['moxi']['package_base_url']`   - The base URL where the packages are located 
* `node['couchbase']['moxi']['package_full_url']`   - The full URL to the moxi package
* `node['couchbase']['moxi']['cluster_server']`     - The bootstrap server for moxi to contact for the node list
* `node['couchbase']['moxi']['cluster_rest_url']`   - The bootstrap server's full REST URL for retrieving the initial node list

Recipes
=======

client
------

Installs the libcouchbase2 and devel packages.

server
------

Installs the couchbase-server package and starts the couchbase-server service.

moxi
----

Installs the moxi-server package and starts the moxi-server service.

Resources/Providers
===================

couchbase_node
--------------

### Actions

* `:modify` - **Default** Modify the configuration of the node

### Attribute Parameters

* `id` - The id of the Couchbase node, typically "self", defaults to the resource name
* `database_path` - The directory the Couchbase node should persist data to
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_node "self" do
  database_path "/mnt/couchbase-server/data"

  username "Administrator"
  password "password"
end
```

couchbase_cluster
-----------------

### Actions

* `:create_if_missing` - **Default** Create a cluster/pool only if it doesn't exist yet

### Attribute Parameters

* `cluster` - The id of the Couchbase cluster, typically "default", defaults to the resource name
* `memory_quota_mb` - The per server RAM quota for the entire cluster in megabytes
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_cluster "default" do
  memory_quota_mb 256

  username "Administrator"
  password "password"
end
```

couchbase_settings
------------------

### Actions

* `:modify` - **Default** Modify the collection of settings

### Attribute Parameters

* `group` - Which group of settings to modify, defaults to the resource name
* `settings` - The hash of settings to modify
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_settings "autoFailover" do
  settings({
    "enabled" => true,
    "timeout" => 30,
  })

  username "Administrator"
  password "password"
end
```

couchbase_bucket
----------------

### Actions

* `:create` - **Default** Create a Couchbase bucket

### Attribute Parameters

* `bucket` - The name to use for the Couchbase bucket, defaults to the resource name
* `cluster` - The name of the cluster the bucket belongs to, defaults to "default"
* `saslPassword` - The password of the bucket, defaults to ""
* `memory_quota_mb` - The bucket's per server RAM quota for the entire cluster in megabytes
* `memory_quota_percent` The bucket's RAM quota as a percent (0.0-1.0) of the cluster's quota
* `replicas` - Number of replica (backup) copies, defaults to 1. Set to false to disable
* `username` - The username to use to authenticate with Couchbase
* `password` - The password to use to authenticate with Couchbase

### Examples

```ruby
couchbase_bucket "default" do
  memory_quota_mb 128
  replicas 2

  username "Administrator"
  password "password"
end

couchbase_bucket "pillowfight" do
  memory_quota_percent 0.5
  replicas false
  saslPassword "bucketPassword"

  username "Administrator"
  password "password"
end
```

Chef Solo Note
==============

These node attributes are stored on the Chef
server when using `chef-client`. Because `chef-solo` does not
connect to a server or save the node object at all, to have the same
passwords persist across `chef-solo` runs, you must specify them in
the `json_attribs` file used. For example:

    {
      "couchbase": {
        "server": {
          "password": "somepassword"
        }
      }
      "run_list":["recipe[couchbase::server]"]
    }

Couchbase Server expects the password to be longer than six characters.

Roadmap
=======

* Sometimes couchbase doesn't come up right away, so we need to add some
  retries in couchbase_node otherwise we get ECONNREFUSED
* Many of the heavyweight resources/providers need to be moved to LWRPs.
* The spec tests are currently broken.

If you have time to work on these things or to improve the cookbook in other ways, please submit a pull request.

License and Author
==================

* Author:: Chris Griego (<cgriego@getaroom.com>)
* Author:: Morgan Nelson (<mnelson@getaroom.com>)
* Author:: Julian Dunn (<jdunn@aquezada.com>)

* Copyright:: 2012, getaroom
* Copyright:: 2012, SecondMarket Labs, LLC.
* Copyright:: 2013, Opscode, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
