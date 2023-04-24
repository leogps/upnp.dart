part of upnp.dial;

class DialScreen {
  static Stream<DialScreen> find({
    bool silent: true
  }) async* {
    var discovery = new DeviceDiscoverer();
    var ids = new Set<String?>();

    await for (DiscoveredClient client in discovery.quickDiscoverClients(
      timeout: const Duration(seconds: 5),
      query: CommonDevices.DIAL
    )) {
      if (ids.contains(client.usn)) {
        continue;
      }
      ids.add(client.usn);

      try {
        var dev = await (client.getDevice() as FutureOr<Device>);
        yield new DialScreen(
          Uri.parse(Uri.parse(client.location!).origin),
          dev.friendlyName
        );
      } catch (e) {
        if (!silent) {
          rethrow;
        }
      }
    }
  }

  final Uri baseUri;
  final String? name;

  DialScreen(this.baseUri, this.name);

  factory DialScreen.forCastDevice(String ip, String deviceName) {
    return new DialScreen(Uri.parse("http://${ip}:8008/"), deviceName);
  }

  Future<bool> isIdle() async {
    StreamedResponse response;
    response = await send("GET", "/apps");
    if (response.statusCode == 302) {
      return false;
    }
    return true;
  }

  Future launch(String app, {payload}) async {
    if (payload is Map) {
      var out = "";
      for (String key in payload.keys as Iterable<String>) {
        if (out.isNotEmpty) {
          out += "&";
        }

        out += "${Uri.encodeComponent(key)}=${Uri.encodeComponent(payload[key].toString())}";
      }
      payload = out;
    }

    StreamedResponse? response;
    response = await send("POST", "/apps/${app}", body: payload);
    if (response.statusCode == 201) {
      return true;
    }
    return false;
  }

  Future<bool> hasApp(String app) async {
    StreamedResponse response;
    response = await send("GET", "/apps/${app}");
    if (response.statusCode == 404) {
      return false;
    }
    return true;
  }

  Future<String?> getCurrentApp() async {
    StreamedResponse response;
    response = await send("GET", "/apps");
    if (response.statusCode == 302) {
      var loc = response.headers["location"]!;
      var uri = Uri.parse(loc);
      return uri.pathSegments[1];
    }
    return null;
  }

  Future<bool> close([String? app]) async {
    var toClose = app == null ? await getCurrentApp() : app;
    if (toClose != null) {
      StreamedResponse response;
      response = await send("DELETE", "/apps/${toClose}");
      if (response.statusCode != 200) {
        return false;
      }
      return true;
    }
    return false;
  }

  Future<StreamedResponse> send(
    String method,
    String path, {
      body,
      Map<String, dynamic>? headers
  }) async {
    Request request = Request(method, baseUri.resolve(path));
    if (body is String) {
      request.body = body;
    } else if (body is List<int>) {
      request.bodyBytes = body;
    }

    if (headers != null) {
      Map<String, String> map = {};
      for (String key in headers.keys) {
        map.putIfAbsent(key, () => headers[key]);
      }
      request.headers.addAll(map);
    }

    return await UpnpCommon.httpClient().send(request);
  }
}
