import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final urlProv = Uri.parse('https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/province.json');
    final urlDist = Uri.parse('https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/district.json');
    final urlSubDist = Uri.parse('https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/sub_district.json');

    print('Fetching Provinces...');
    final pRes = await HttpClient().getUrl(urlProv).then((req) => req.close());
    final pData = jsonDecode(await pRes.transform(utf8.decoder).join()) as List;

    print('Fetching Districts...');
    final dRes = await HttpClient().getUrl(urlDist).then((req) => req.close());
    final dData = jsonDecode(await dRes.transform(utf8.decoder).join()) as List;

    print('Fetching Sub-districts...');
    final sRes = await HttpClient().getUrl(urlSubDist).then((req) => req.close());
    final sData = jsonDecode(await sRes.transform(utf8.decoder).join()) as List;

    final Map<int, String> provMap = {};
    for (var p in pData) {
      provMap[p['id']] = p['name_th'].toString().trim();
    }

    final Map<int, String> distMap = {};
    final Map<int, int> distToProv = {};
    for (var d in dData) {
      distMap[d['id']] = d['name_th'].toString().trim();
      distToProv[d['id']] = d['province_id'];
    }

    final Map<String, Map<String, List<String>>> result = {};

    for (var s in sData) {
      int distId = s['district_id'] ?? s['amphure_id'] ?? -1;
      if (distId == -1) continue;
      
      String subDistName = s['name_th'].toString().trim();
      String distName = distMap[distId] ?? 'Unknown';
      int provId = distToProv[distId] ?? -1;
      String provName = provMap[provId] ?? 'Unknown';

      if (provName == 'Unknown' || distName == 'Unknown') continue;

      result.putIfAbsent(provName, () => {});
      result[provName]!.putIfAbsent(distName, () => []);
      if (!result[provName]![distName]!.contains(subDistName)) {
        result[provName]![distName]!.add(subDistName);
      }
    }

    final file = File('lib/thai_districts.dart');
    final buffer = StringBuffer();
    buffer.writeln('// Auto-generated Thai address mapping');
    buffer.writeln('const Map<String, Map<String, List<String>>> thaiAddressTree = {');
    
    for (var pName in result.keys) {
      buffer.writeln("  '$pName': {");
      var districts = result[pName]!;
      for (var dName in districts.keys) {
        var subDistricts = districts[dName]!;
        buffer.writeln("    '$dName': [${subDistricts.map((v) => "'$v'").join(', ')}],");
      }
      buffer.writeln("  },");
    }
    buffer.writeln('};');
    
    await file.writeAsString(buffer.toString());
    print('Done! Saved to lib/thai_districts.dart');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
