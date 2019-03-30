# Tengine Build Script

This is a Bash script for building [Tengine](http://tengine.taobao.org/). It has been written for and tested on Ubuntu 18.x It has the following features:

- No email or other guff
- Non-thread pool
- Forward proxying
- [JEMalloc](http://jemalloc.net/)
- Creates `nginx` user and group
- Creates all temp directories
- Creates a `.service` file for `systemd` integration

Copy it into `/opt`, do a `chmod u+x tengine-build.sh` and run it.

## License

Unless otherwise specified, all code is released under the MIT License (MIT). See the [repository's `LICENSE` file](https://github.com/jlyonsmith/nginx-build/blob/master/LICENSE) for details.
