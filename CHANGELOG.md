## v1.3.2 (2015-08-28)

- Revert package_machine calculation - broke some environments
- trigger block[block_until_operational] upon package install on debian
- password reset occurs when unnecessary, was logging users out of GUI
- correct couchbase 3.0.0 location
- pass authentication as header, not on URI (deprecated functionality)

## v1.3.1 (2015-05-01)

- Remove resource cloning.
- Fix package version naming, etc. for current releases.
- [GH-43] Bugfix: URI encode the server path. 

## v1.3.0 (2014-10-25)

- Update to Couchbase 3.0.0.
- Update to Moxi Server 2.5.0.
- Update unit tests to rspec3
- [GH-28] Added index_path

## v1.2.0 (2014-04-10)

- Update to Couchbase 2.2.0.
- [GH-13] Add 'buckets' recipe to manipulate buckets.
- [GH-19] Repair Ubuntu package name changes.

## v1.1.0

- Update to Couchbase 2.0.1.
- Add Test Kitchen 1.0.0 support and integration with Travis CI.
- [GH-2] Add a helper to check that Couchbase is actually up before trying to create buckets, etc.
- [GH-4] Allow SASL passwords to be used as bucket passwords
- [GH-7] Only set password if not set at other precedence levels. Also remove unnecessary node.save
- [GH-8] Added extra dep on libssl0.9.8 on Debian/Ubuntu
- [GH-9] Don't hardcode install_dir, use the node attribute instead
- [GH-10] Fix broken spec tests from GH-4
- [GH-11] Couchbase doesn't sign their packages, so on some RHEL distributions make sure we do --nogpgcheck

## v1.0.0

- Initial release
