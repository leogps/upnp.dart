import "package:upnp/upnp.dart";

main() async {
  var disc = new DeviceDiscoverer();
  await disc.start(ipv4: true, ipv6: true, tracePackets: true);
  List<DiscoveredClient> clients = await disc.discoverClients(timeout: Duration(seconds: 5));
  print("Devices found ${clients.length}");
  clients.forEach((client) async {
    try {
      print(client);
      var dev = await client.getDevice();
      print("${dev!.friendlyName}: ${dev.url}");
    } catch (e, stack) {
      print("ERROR: ${e} - ${client.location}");
      print(stack);
    }
  });
}
