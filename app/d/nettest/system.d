import driver;

import pci.pci;

extern(C) void initC2D();

import user.syscall;

import user.environment;
import user.ipc;

import console;

class System {
static:
public:
  NetworkDriver networkDriver() {
    _initialize();

    if (_networkDriver is null) {
      _networkDriver = new NetworkDriver();
    }

    return _networkDriver;
  }

private:

  void _initialize() {
    if (_initialized) {
      return;
    }

    initC2D();
    _initialized = true;
  }

  bool _initialized;

  NetworkDriver _networkDriver;
}
