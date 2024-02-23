# Tengine Build Script

This is a Bash script for building [Tengine](http://tengine.taobao.org/). It has been written for and tested on Ubuntu 18.x and 20.x It has the following features:

- No email or other guff
- Non-thread pool
- Forward proxying
- [JEMalloc](http://jemalloc.net/)
- Creates `nginx` user and group
- Creates all temp directories
- Creates a `.service` file for `systemd` integration
- IPv6 support
- No FastCGI support

Clone the repo and run `build-tengine.sh`.  The script must be run as `sudo` (it will tell you.)

## License

Unless otherwise specified, all code is released under the MIT License (MIT). See the [repository's `LICENSE` file](https://github.com/jlyonsmith/nginx-build/blob/master/LICENSE) for details.
