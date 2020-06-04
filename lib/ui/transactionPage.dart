import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:govm/generated/i18n.dart';
import 'package:govm/ui/diag.dart';
import 'package:govm/util/transaction.dart';
import 'package:govm/util/util.dart' as util;
import 'package:govm/wallet/wallet.dart';
import 'package:hex/hex.dart';

class TransactionWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new TransactionWidgetState();
  }
}

String _chain = '1';
String _dstChain = '2';

class TransactionWidgetState extends State<TransactionWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.of(context).transaction),
        ),
        body: DefaultTabController(
          length: 4,
          child: Column(
            children: <Widget>[
              Container(
                  color: Colors.blue,
                  child: TabBar(
                    indicatorWeight: 3.0,
                    indicatorColor: Colors.grey,
                    tabs: <Widget>[
                      Tab(text: I18n.of(context).transfer),
                      Tab(text: I18n.of(context).move),
                      Tab(text: I18n.of(context).vote),
                      Tab(text: I18n.of(context).cancelVote),
                    ],
                  )),
              Expanded(
                  flex: 1,
                  child: TabBarView(
                    children: <Widget>[
                      getTransferWidget(),
                      getMoveWidget(),
                      getVoteWidget(),
                      cancelVoteWidget(),
                    ],
                  ))
            ],
          ),
        ));
  }

  Future<String> _scan<T>() async {
    try {
      var result = await BarcodeScanner.scan();
      // print(result.type); // The result type (barcode, cancelled, failed)
      // print(result.rawContent); // The barcode content
      // print(result.format); // The barcode format (as enum)
      // print(result.formatNote);
      return result.rawContent;
    } catch (err) {
      return '';
    }
  }

  Widget getTransferWidget() {
    GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
    TextEditingController peerController = new TextEditingController();
    TextEditingController costController = new TextEditingController();
    var _chains = util.allChains.map((num i) {
      return DropdownMenuItem(
        value: '$i',
        child: Text(I18n.of(context).chainID('$i')),
      );
    }).toList();

    var chainW = DropdownButton(
      isExpanded: true,
      value: _chain,
      items: _chains,
      onChanged: (String selected) {
        _chain = selected;
        setState(() {});
      },
    );
    var peerW = new TextFormField(
      keyboardType: TextInputType.text,
      controller: peerController,
      maxLines: 2,
      decoration: new InputDecoration(
        labelText: I18n.of(context).peerAddr,
        // prefixIcon: Icon(Icons.person),
        suffixIcon: IconButton(
          onPressed: () {
            _scan().then((String val) {
              if (val.startsWith('govm')) {
                val = val.substring(5);
              }
              peerController.text = val;
            });
          },
          icon: Image.asset(
            'images/scanning.jpg',
            height: 20.0,
            fit: BoxFit.cover,
          ),
        ),
      ),
      validator: (val) {
        try {
          var dec = HEX.decode(val);
          if (dec.length != 24) {
            return I18n.of(context).addrError;
          }
        } catch (err) {
          return I18n.of(context).addrError;
        }
        return null;
      },
    );

    var costW = new TextFormField(
      keyboardType: TextInputType.number,
      controller: costController,
      decoration: new InputDecoration(labelText: 'Cost: ' + util.unit),
      // obscureText: true,
      validator: (val) {
        try {
          var v = double.parse(val);
          if (v < 0) {
            return I18n.of(context).lessThan0;
          }
        } catch (err) {
          return I18n.of(context).mustNum;
        }
        return null;
      },
    );
    return Scaffold(
        floatingActionButton: new FloatingActionButton(
          onPressed: () {
            var _form = _formKey.currentState;
            if (_form.validate()) {
              _form.save();
              try {
                var v = double.parse(costController.text);
                var cost = v * util.getBaseOfUnit(u: util.unit);
                if (cost.floor() <= 0) {
                  myDiag(context, I18n.of(context).eCost+':${costController.text}');
                  return;
                }
                var have = util.accounts['$_chain.${wallet.address}'];
                if(have == null || have.balance == null || cost.floor()+defaultEnergy > have.balance){
                  myDiag(context, I18n.of(context).noMoney);
                  costController.text = '';
                  return;
                }
                Transaction trans =
                    new Transaction(wallet.address, _chain, cost.floor());
                trans.opsTransfer(peerController.text);
                var data = trans.getSignData();
                var sign = wallet.doSign(data);
                trans.setSign(sign);
                var out = trans.output();
                var transKey = Wallet.doGovmHash(out);
                util
                    .sendTransaction(_chain, HEX.encode(transKey), out)
                    .then((String rst) {
                  myDiag(context, 'success:$rst');
                  peerController.text = '';
                  costController.text = '';
                }).catchError((err){
                  myDiag(context, 'fail:$err', title: 'error');
                });
              } catch (err) {
                myDiag(context, 'fail:$err', title: 'error');
              }
            }
          },
          child: new Text(I18n.of(context).submit),
        ),
        body: Scrollbar(
            child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: new Form(
              key: _formKey,
              child: new Column(
                children: <Widget>[
                  chainW,
                  peerW,
                  costW,
                ],
              ),
            ),
          ),
        )));
  }

  Widget getMoveWidget() {
    GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
    TextEditingController costController = new TextEditingController();
    var _chains = util.allChains.map((num i) {
      return DropdownMenuItem(
        value: '$i',
        child: Text(I18n.of(context).fromChain('$i')),
      );
    }).toList();
    var _dstChains = util.allChains.map((num i) {
      return DropdownMenuItem(
        value: '$i',
        child: Text(I18n.of(context).toChain('$i')),
      );
    }).toList();

    var chainW = DropdownButton(
      isExpanded: true,
      value: _chain,
      items: _chains,
      onChanged: (String selected) {
        _chain = selected;
        setState(() {});
      },
    );
    var dstChainW = DropdownButton(
      isExpanded: true,
      // icon: Icon(Icons.chevron_left),
      value: _dstChain,
      items: _dstChains,
      onChanged: (String selected) {
        _dstChain = selected;
        setState(() {});
      },
    );

    var costW = new TextFormField(
      keyboardType: TextInputType.number,
      controller: costController,
      decoration: new InputDecoration(
        labelText: 'Cost: ' + util.unit,
      ),
      // obscureText: true,
      validator: (val) {
        try {
          var v = double.parse(val);
          if (v < 0) {
            return I18n.of(context).lessThan0;
          }
          if (_chain == _dstChain) {
            return I18n.of(context).equalChain;
          }
        } catch (err) {
          return I18n.of(context).mustNum;
        }
        return null;
      },
    );

    return Scaffold(
        floatingActionButton: new FloatingActionButton(
          onPressed: () {
            var _form = _formKey.currentState;
            if (_form.validate()) {
              _form.save();
              try {
                print('dst chain:$_dstChain, cost:${costController.text}');
                var v = double.parse(costController.text);
                var valT0 = v * util.getBaseOfUnit(u: util.unit);
                var cost = valT0.floor();
                if (cost <= 0) {
                  myDiag(context, I18n.of(context).lessThan0+':${costController.text}');
                  return;
                }
                var have = util.accounts['$_chain.${wallet.address}'];
                if(have == null || have.balance == null || cost+defaultEnergy > have.balance){
                  myDiag(context, I18n.of(context).noMoney);
                  costController.text = '';
                  return;
                }
                Transaction trans =
                    new Transaction(wallet.address, _chain, cost);
                trans.opsMove(_dstChain);
                var data = trans.getSignData();
                var sign = wallet.doSign(data);
                trans.setSign(sign);
                var out = trans.output();
                var transKey = Wallet.doGovmHash(out);
                util.sendTransaction(_chain, HEX.encode(transKey), out)
                    .then((String rst) {
                  myDiag(context, 'success:$rst');
                  costController.text = '';
                }).catchError((err){
                  myDiag(context, 'fail:$err', title: 'error');
                });
              } catch (err) {
                myDiag(context, 'fail:$err', title: 'error');
              }
            }
          },
          child: new Text(I18n.of(context).submit),
        ),
        body: Scrollbar(
            child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: new Form(
              key: _formKey,
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(I18n.of(context).moveDesc),
                  chainW,
                  dstChainW,
                  costW,
                ],
              ),
            ),
          ),
        )));
  }

  
  Widget getVoteWidget() {
    GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
    TextEditingController peerController = new TextEditingController();
    TextEditingController votesController = new TextEditingController();
    peerController.text = "01ccaf415a3a6dc8964bf935a1f40e55654a4243ae99c709";
    var _chains = util.allChains.map((num i) {
      return DropdownMenuItem(
        value: '$i',
        child: Text(I18n.of(context).chainID('$i')),
      );
    }).toList();

    var chainW = DropdownButton(
      isExpanded: true,
      value: _chain,
      items: _chains,
      onChanged: (String selected) {
        _chain = selected;
        setState(() {});
      },
    );
    var peerW = new TextFormField(
      keyboardType: TextInputType.text,
      controller: peerController,
      maxLines: 2,
      decoration: new InputDecoration(
        labelText: I18n.of(context).peerAddr,
        // prefixIcon: Icon(Icons.person),
        suffixIcon: IconButton(
          onPressed: () {
            _scan().then((String val) {
              if (val.startsWith('govm')) {
                val = val.substring(5);
              }
              peerController.text = val;
            });
          },
          icon: Image.asset(
            'images/scanning.jpg',
            height: 20.0,
            fit: BoxFit.cover,
          ),
        ),
      ),
      validator: (val) {
        try {
          var dec = HEX.decode(val);
          if (dec.length != 24) {
            return I18n.of(context).addrError;
          }
        } catch (err) {
          return I18n.of(context).addrError;
        }
        return null;
      },
    );

    var costW = new TextFormField(
      keyboardType: TextInputType.number,
      controller: votesController,
      decoration: new InputDecoration(labelText: 'Votes: 1govm per vote'),
      // obscureText: true,
      validator: (val) {
        try {
          var v = double.parse(val);
          if (v < 0) {
            return I18n.of(context).lessThan0;
          }
        } catch (err) {
          return I18n.of(context).mustNum;
        }
        return null;
      },
    );
    return Scaffold(
        floatingActionButton: new FloatingActionButton(
          onPressed: () {
            var _form = _formKey.currentState;
            if (_form.validate()) {
              _form.save();
              try {
                var v = int.parse(votesController.text);
                var cost = v * util.voteCost;
                if (cost < 0) {
                  myDiag(context, I18n.of(context).eCost+':${votesController.text}');
                  return;
                }
                var have = util.accounts['$_chain.${wallet.address}'];
                if(have == null || have.balance == null || cost+defaultEnergy > have.balance){
                  myDiag(context, I18n.of(context).noMoney);
                  votesController.text = '';
                  return;
                }
                Transaction trans = new Transaction(wallet.address, _chain, cost);
                trans.opsVote(peerController.text);
                var data = trans.getSignData();
                var sign = wallet.doSign(data);
                trans.setSign(sign);
                var out = trans.output();
                var transKey = Wallet.doGovmHash(out);
                util.sendTransaction(_chain, HEX.encode(transKey), out)
                    .then((String rst) {
                  myDiag(context, 'success:$rst');
                  votesController.text = '';
                }).catchError((err){
                  myDiag(context, 'fail:$err', title: 'error');
                });
              } catch (err) {
                print("fail to vote--$err");
                myDiag(context, 'fail:$err', title: 'error');
              }
            }
          },
          child: new Text(I18n.of(context).submit),
        ),
        body: Scrollbar(
            child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: new Form(
              key: _formKey,
              child: new Column(
                children: <Widget>[
                  chainW,
                  peerW,
                  costW,
                ],
              ),
            ),
          ),
        )));
  }


  Widget cancelVoteWidget() {
    GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
    var _chains = util.allChains.map((num i) {
      return DropdownMenuItem(
        value: '$i',
        child: Text(I18n.of(context).chainID('$i')),
      );
    }).toList();

    var chainW = DropdownButton(
      isExpanded: true,
      value: _chain,
      items: _chains,
      onChanged: (String selected) {
        _chain = selected;
        setState(() {});
      },
    );
    
    return Scaffold(
        floatingActionButton: new FloatingActionButton(
          onPressed: () {
            var _form = _formKey.currentState;
            if (_form.validate()) {
              _form.save();
              try {
                var have = util.accounts['$_chain.${wallet.address}'];
                if(have == null || have.balance == null || defaultEnergy > have.balance){
                  myDiag(context, I18n.of(context).noMoney);
                  return; 
                }
                Transaction trans =
                    new Transaction(wallet.address, _chain, 0);
                trans.opsUnvote();
                var data = trans.getSignData();
                var sign = wallet.doSign(data);
                trans.setSign(sign);
                var out = trans.output();
                var transKey = Wallet.doGovmHash(out);
                util.sendTransaction(_chain, HEX.encode(transKey), out)
                    .then((String rst) {
                  myDiag(context, 'success:$rst');
                }).catchError((err){
                  myDiag(context, 'fail:$err', title: 'error');
                });
              } catch (err) {
                myDiag(context, 'fail:$err', title: 'error');
              }
            }
          },
          child: new Text(I18n.of(context).submit),
        ),
        body: Scrollbar(
            child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: new Form(
              key: _formKey,
              child: new Column(
                children: <Widget>[
                  Text("cancel votes and deposit refund"),
                  chainW,
                ],
              ),
            ),
          ),
        )));
  }

}
