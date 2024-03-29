import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.device});
  //장치 정보 전달받기
  final BluetoothDevice device;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  //연결상태 표시문자열
  String stateText = 'Connecting';

  //연결 버튼 문자열
  String connectButtonText = 'Disconnect';

  //현재 연결 상태 저장용
  BluetoothConnectionState deviceState = BluetoothConnectionState.disconnected;

  //연결 상태 리스너 핸들 화면 종료시 리스너 해제를 위함
  StreamSubscription<BluetoothConnectionState>? _stateListener;

  //연결된 장치의 서비스 정보를 저장
  List<BluetoothService> bluetoothService = [];

  //
  Map<String, List<int>> notifyDatas = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //상태 연결 리스너 등록
    _stateListener = widget.device.connectionState.listen((event) {
      debugPrint('event : $event');
      if (deviceState == event) {
        //상태가 동일하면 무시
        return;
      }
      //연결 상태 정보 변경
      setBleConnectionState(event);
    });
    //연결시작
    connect();
  }

  @override
  void dispose() {
    //상태 리스너 해제
    _stateListener?.cancel();
    //연결 해제
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    //화면이 mounted 되었을때만 업데이트 되게 함
    if (mounted) {
      super.setState(fn);
    }
  }

  setBleConnectionState(BluetoothConnectionState event) {
    switch (event) {
      case BluetoothConnectionState.disconnected:
        stateText = 'Disconnected';
        //버튼 상태 변경
        connectButtonText = 'Connect';
        break;
      case BluetoothConnectionState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothConnectionState.connected:
        stateText = 'Connected';
        //버튼상태변경
        connectButtonText = 'Disconnect';
        break;
      case BluetoothConnectionState.connecting:
        stateText = 'Connecting';
        break;
    }
    deviceState = event;
    setState(() {});
  }

  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      //상태 표시를 Connection으로 변경
      stateText = 'Connecting';
    });

    // 타임아웃을 15초(15000ms)로 설정 및 autoconnect 해제
    // autoconnect가 true로 되어있으면 연결이 지연되는 경우가 있음
    await widget.device
        .connect(autoConnect: false)
        .timeout(const Duration(milliseconds: 15000), onTimeout: () {
      //타임아웃 발생
      //returnValue를 false로 설정
      returnValue = Future.value(false);
      debugPrint('timeout failed');

      //연결 상태 disconnected로 변경
      setBleConnectionState(BluetoothConnectionState.disconnected);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        //returnValue가 null이면 timeout이 발생한 것이 아니므로 연결 성공
        debugPrint('connection successful');
        print('start discover service');
        List<BluetoothService> bleServices =
            await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });
        //각 속성을 디버그에 출력
        for (BluetoothService service in bleServices) {
          print("====================================================");
          print('Service UUID: ${service.uuid}');
          for (BluetoothCharacteristic c in service.characteristics) {
            print('\tcharacteristic UUID: ${c.uuid.toString()}');
            print('\t\twrite: ${c.properties.write}');
            print('\t\tread: ${c.properties.read}');
            print('\t\tnotify: ${c.properties.notify}');
            print('\t\tisNotifying: ${c.isNotifying}');
            print(
                '\t\twriteWithoutResponse: ${c.properties.writeWithoutResponse}');
            print('\t\tindicate: ${c.properties.indicate}');

            //notify나 indicate가 true면 device에서 데이터를 보낼 수 있는 캐릭터리스틱이니 활성화한다.
            //단, descriptors가 비었으면 notify를 할 수 없으므로 패스!
            if (c.properties.notify && c.descriptors.isNotEmpty) {
              //0x2902가 있는지 단순 체크
              // for (BluetoothDescriptor d in c.descriptors) {
              //   print('BluetoothDescriptor uuid ${d.uuid}');
              //   if (d.uuid == BluetoothDescriptor.cccd) {
              //     print('d.lastValue: ${d.lastValue}');
              //   }
              // }
              if (!c.isNotifying) {
                try {
                  await c.setNotifyValue(true);
                  //받을 데이터 변수 Map 형식으로 키생성
                  notifyDatas[c.uuid.toString()] = List.empty();
                  c.lastValueStream.listen((value) {
                    //데이터 읽기 처리
                    print('{${c.uuid}: $value}');
                    setState(() {
                      // 받은 데이터 저장 화면 표시용
                      notifyDatas[c.uuid.toString()] = value;
                    });
                  });

                  //설정후 일정시간 지연
                  await Future.delayed(const Duration(milliseconds: 500));
                } catch (e) {
                  print('error ${c.uuid} $e');
                }
              }
            }
          }
        }
        returnValue = Future.value(true);
      }
    });

    return returnValue ?? Future.value(false);
  }

//연결해제
  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch (e) {}
  }

  //Write
  void writeData(List<int> data, BluetoothCharacteristic characteristic) {
    print(data.toString());
    characteristic.write(
      data,
      withoutResponse: true,
    );
  }

  //notify 종료
  void stopNotification(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //장치명
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.device.platformName),
            OutlinedButton(
                onPressed: () {
                  if (deviceState == BluetoothConnectionState.connected) {
                    //버튼 신호보내기
                    //writeData(넣을데이터 , 장비characteristic);
                  }
                },
                child: const Text('Send Signal'))
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //연결상태
                Text(stateText),
                //연결 및 해제 버튼
                OutlinedButton(
                    onPressed: () {
                      if (deviceState == BluetoothConnectionState.connected) {
                        //연결상태면 연결해제
                        disconnect();
                      } else if (deviceState ==
                          BluetoothConnectionState.disconnected) {
                        //연결해제 상태면 연결
                        connect();
                      }
                    },
                    child: Text(connectButtonText)),
              ],
            ),
            //연결된 BLE의 서비스 정보 출력
            Expanded(
              child: ListView.separated(
                itemCount: bluetoothService.length,
                itemBuilder: (context, index) {
                  return listItem(bluetoothService[index]);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  //각 캐릭터리스틱 정보 표시 위젝
  Widget characteristicInfo(BluetoothService r) {
    String name = '';
    String properties = '';
    String data = '';
    //캐릭터리스틱을 한개씩 꺼내 표시
    for (BluetoothCharacteristic c in r.characteristics) {
      properties = '';
      data = '';
      name += '\t\t${c.uuid}\n';
      if (c.properties.write) {
        properties += 'Write ';
      }
      if (c.properties.read) {
        properties += 'Read ';
      }
      if (c.properties.notify) {
        properties += 'Notify ';
        if (notifyDatas.containsKey(c.uuid.toString())) {
          //notify 데이터가 존재한다면
          if (notifyDatas[c.uuid.toString()]!.isNotEmpty) {
            data = notifyDatas[c.uuid.toString()].toString();
          }
        }
      }
      if (c.properties.writeWithoutResponse) {
        properties += 'WriteWR ';
      }
      if (c.properties.indicate) {
        properties += 'Indicate ';
      }
      name += '\t\t\tProperties: $properties\n';
    }
    return Text(name);
  }

//Service UUID 위젯
  Widget serviceUUID(BluetoothService r) {
    String name = '';
    name = r.uuid.toString();
    return Text(name);
  }

//service 정보아이템위젯
  Widget listItem(BluetoothService r) {
    return ListTile(
      onTap: null,
      title: serviceUUID(r),
      subtitle: characteristicInfo(r),
    );
  }
}
