import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PlatformFile? pickedFile;
  UploadTask? uploadTask;
  String downloadUrl="";
Future selectFile() async {
  final result = await FilePicker.platform.pickFiles(); 
  if(result==null) return;
  setState(() {
    pickedFile= result.files.first;

  },);
}
Future uploadFile() async {
  
  final path = "files/${pickedFile!.name}";
  final file = File(pickedFile!.path!); 

  int sizeInBytes = file.lengthSync();
double sizeInMb = sizeInBytes / (1024 * 1024);
if (sizeInMb < 10){
     final ref= FirebaseStorage.instance.ref().child(path);
  setState(() {
     uploadTask= ref.putFile(file);

  });
 final snapshot =await uploadTask!.whenComplete(() {});
downloadUrl =await snapshot.ref.getDownloadURL();
setState(() {
  uploadTask= null;
});
}

 }

 

  @override
  Widget build(BuildContext context) {
 
    return Scaffold(
      appBar: AppBar(
     
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
       
        title: Text(widget.title),
      ),
      body: Center(
     
        child: Column(
    
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (pickedFile!=null)?Expanded(
              child: Container(
                color: Colors.blue,
                child: Image.file(File(pickedFile!.path!),width: double.infinity,fit: BoxFit.cover,)),
            )
:Container()
            ,
            ElevatedButton(onPressed:  selectFile, child: const Text(
              'Choose File',
            ),),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(onPressed: uploadFile, child: const Text(
              'Upload File',
            ),),
             ElevatedButton(onPressed: () async {
               final Uri url = Uri.parse(downloadUrl);
 if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
 }
            }, child: const Text(
              'Go to Uploaded File',
            ),),
            
            buildProgress(),
          ],
        ),
      ),
    );
  }
Widget  buildProgress(){
  return  StreamBuilder<TaskSnapshot>(
    stream: uploadTask?.snapshotEvents,
    builder: (context, snapshot) {   
      if (snapshot.hasData) {
          final data= snapshot.data!;
final progress = data.bytesTransferred/data.totalBytes;
return SizedBox(
  height: 50,
  child: Stack(
    fit: StackFit.expand,
    children: [
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.black,
        color: Colors.red,

      ),
      Center(
        child: Text("${(100 * progress).roundToDouble()}%",style: const TextStyle(color: Colors.white),),
      )
    ],
  ),
);  
        } else {
            if (snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'canceled') {
        return const Text('Upload canceled.');
          } else {
            print(snapshot.error);
      return SizedBox(height: 50,);
          }
         }
    },
    );
  }
}
