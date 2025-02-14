import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'QROrderPage.dart';
import 'stateContext.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({Key? key}) : super(key: key);

  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  //funzionamento hot reload android: mettere in pausa la fotocamera
  //funzionamento hot reload iOS: far ripartire
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (stateContext.getState().getResult() == null)
                    //risultato assente
                    const Padding(
                        child: Text('Scan a code...',
                            style: TextStyle(fontSize: 10)),
                        padding: EdgeInsets.all(5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              if (snapshot.data != true) {
                                //flash attivo
                                return ElevatedButton(
                                    onPressed: () async {
                                      await controller?.toggleFlash();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.flash_off),
                                    style: ElevatedButton.styleFrom(
                                        primary: Colors.black));
                              }
                              //flash disattivato
                              return ElevatedButton(
                                  key: Key("flash"),
                                  onPressed: () async {
                                    await controller?.toggleFlash();
                                    setState(() {});
                                  },
                                  child:
                                      Icon(Icons.flash_on, color: Colors.black),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white,
                                  ));
                            },
                          )),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  //costruzione della visualizzazione fotocamera che permette di inquadrare il QR Code
  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 300.0
        : 400.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    if (stateContext.getState().getBarcodeResult() == "") {
      setState(() {
        this.controller = controller;
      });
      //il controller di mette in ascolto attendendo l'inquadratura di un QR valido
      controller.scannedDataStream.listen((scanData) {
        var count = 0;
        //ciò che è stato scannerizzato va nello stateContext
        setState(() {
          stateContext.getState().setResult(scanData);
          if (count == 0) {
            count++;
            stateContext
                .getState()
                .setBarcodeResult(stateContext.getState().getResult()!.code);
            Navigator.of(context).pop();
            //apertura della pagina successiva (visualizzazione ordine)
            Navigator.of(context).push(_createRoute2());
            controller.pauseCamera();
          }
        });
      });
    }
  }

  //funzione che permette il cambio di pagina su flutter, crea una nuova istanza del widget della pagina successiva (QROrderPage)
  Route _createRoute2() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => QROrderPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
