import 'dart:convert';
import 'dart:io';

void main() async {
  final urlProv = Uri.parse('https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/province.json');
  final pRes = await HttpClient().getUrl(urlProv).then((req) => req.close());
  final pData = jsonDecode(await pRes.transform(utf8.decoder).join()) as List;
  print('Province Sample: ${pData[0]}');

  final urlDist = Uri.parse('https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/district.json');
  final dRes = await HttpClient().getUrl(urlDist).then((req) => req.close());
  final dData = jsonDecode(await dRes.transform(utf8.decoder).join()) as List;
  print('District Sample: ${dData[0]}');

  final urlSubDist = Uri.parse('https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/sub_district.json');
  final sRes = await HttpClient().getUrl(urlSubDist).then((req) => req.close());
  final sData = jsonDecode(await sRes.transform(utf8.decoder).join()) as List;
  print('Sub-district Sample: ${sData[0]}');
}
