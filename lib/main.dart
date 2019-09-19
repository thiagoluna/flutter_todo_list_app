import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _tarefaController = TextEditingController();

  List _listaTarefas = []; //lista de tarefas
  //Mapa que vai armazenar o último item da lista removido
  Map<String, dynamic> _lastExcluido;
  int _lastExcluidoPos; //posicao na lista


  @override
  void initState() { // reescrever esse metodo pra pegar os dados do json
    super.initState(); // na inicializacao do App
    _lerDados().then((data){  //usar then pq é um Future
      setState(() {
        _listaTarefas = json.decode(data);
      });
    });
  }

  void _gravarEnter(){
    _addTarefa();
  }

  void _addTarefa(){  //inserir tarefa na lista
    setState(() {  //mudar o estado da tela quando gravar
      Map<String, dynamic> novaTarefa = Map();
      //Pegando o texto digitado e colocando na area titulo do mapa
      if(_tarefaController.text.isEmpty) { //se campo vazio não faz nada
      }else{  //se tiver texto grava
        novaTarefa["title"] = _tarefaController.text;
        _tarefaController.text = ""; //limpando o textfield apos gravar
        novaTarefa["ok"] = false;
        _listaTarefas.add(novaTarefa);
        _salvarDados();
      }
    });
  }

  //funcao pra atualizar a tela quando arrastar pra baixo
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1)); //esperar 1 segundo
    setState(() {
      _listaTarefas.sort((a, b){  //colocar os não marcados primeiro
        if(a["ok"] && !b["ok"])return 1;
        else if(!a["ok"] && b["ok"])return -1;
        else return 0;
      });
      //return a["title"].toLowerCase().compareTo(b["title"].toLowerCase());
      _salvarDados();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column( //App com uma coluna e os widgets embaixo do outro
        children: <Widget>[
          Container(  //primeiro widget
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                //Campo para digitar as tarefas dentro do Expanded
                Expanded( //definir o comprimento do campo na linha
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                    controller: _tarefaController,
                    onSubmitted: (String str){ //usar o Enter do teclado pra gravar
                      _addTarefa();
                    },
                  ),
                ),
                //Botão de Adicionar
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: _addTarefa,
                )
              ],
            ),
          ),
          Expanded(  //segundo widget dentro do expanded p/ pegar a tela toda
            child: RefreshIndicator(onRefresh: _refresh,
              child: ListView.builder( //construir uma lista de tarefas
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _listaTarefas.length, //fazer do tamalho da lista
                  //chamar a funcao buildItem para montar a lista de tarefas
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  //Função pra montar cada linha da lista de tarefas
  Widget buildItem(context, index){
    return Dismissible( //widget permite arrastar para direita pra apagar
      //definir uma key que vai pegar cada linha da lista
      //key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      key: ObjectKey(_listaTarefas[index]),
      background: Container(
        color: Colors.red, //fundo vermelho
        child: Align( //alinhar o filho no canto esquerdo
          alignment: Alignment(-0.9, 0.0), //alinhar a esquerda
          child: Icon(Icons.delete, color: Colors.white)//adiciona icone lixeira
        ),
      ),
      direction: DismissDirection.startToEnd, //arrastar da esquerda p/ direita
      child: CheckboxListTile(  //os itens com checkbox no final
        title: Text(_listaTarefas[index]["title"],
          style: TextStyle(color: _listaTarefas[index]["ok"] ? Colors.green : Colors.black),),
        value: _listaTarefas[index]["ok"],
        secondary: CircleAvatar( // icone no inicio da linha
          child: Icon(_listaTarefas[index]["ok"] ? //se for ok marca o check
          Icons.check : Icons.error),
        ),
        onChanged: (c){  //pega o clik no checkbox
          setState(() {//grava o click e muda o estdado do checkbox
            _listaTarefas[index]["ok"] = c;
            _salvarDados();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          _lastExcluido = Map.from(_listaTarefas[index]); //guarda item excluido
          _lastExcluidoPos = index; //guarda a posicao
          _listaTarefas.removeAt(index); //remove item da lista
          _salvarDados(); //salvar lista atualizada

          //Criar Snackbar
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastExcluido["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState(() {
                  _listaTarefas.insert(_lastExcluidoPos, _lastExcluido);
                  _salvarDados();
                });
              }),
            duration: Duration(seconds: 3),
          );

          //Mostrar Snackbar na parte inferior da tela
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }


  //Função para pegar os dados do arquivo
  Future<File> _getFile() async{
    //variavel diretorio recebe o caminho direto do getApplication...
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/tarefas.json");
  }

  //Função para gravar os dados
  Future<File> _salvarDados() async{
    String dado = json.encode(_listaTarefas);
    final arquivo = await _getFile();
    return arquivo.writeAsString(dado);
  }

  //Função para ler os dados
  Future<String> _lerDados() async{
    try{
      final arquivo = await _getFile();
      return arquivo.readAsString();
    }catch(e){
      return null;
    }
  }
}

