
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const RiceMillApp());

class Product {
  Product(this.name, {this.bagKg = 50, this.stockKg = 0});
  String name;
  double bagKg, stockKg;
  double producedKg = 0, purchasedKg = 0, soldKg = 0;
  double purchaseCost = 0, productionCost = 0, salesAmount = 0;
  Map<String,dynamic> toJson()=>{'name':name,'bagKg':bagKg,'stockKg':stockKg,
    'producedKg':producedKg,'purchasedKg':purchasedKg,'soldKg':soldKg,
    'purchaseCost':purchaseCost,'productionCost':productionCost,'salesAmount':salesAmount};
  factory Product.fromJson(Map<String,dynamic> j){
    final p=Product(j['name'],bagKg:(j['bagKg']??50).toDouble(),stockKg:(j['stockKg']??0).toDouble());
    p.producedKg=(j['producedKg']??0).toDouble(); p.purchasedKg=(j['purchasedKg']??0).toDouble();
    p.soldKg=(j['soldKg']??0).toDouble(); p.purchaseCost=(j['purchaseCost']??0).toDouble();
    p.productionCost=(j['productionCost']??0).toDouble(); p.salesAmount=(j['salesAmount']??0).toDouble(); return p;
  }
}
class Customer {
  Customer(this.name,{this.phone='',this.address=''});
  String name,phone,address;
  double balance=0;
  Map<String,dynamic> toJson()=>{'name':name,'phone':phone,'address':address,'balance':balance};
  factory Customer.fromJson(Map<String,dynamic> j){final c=Customer(j['name'],phone:j['phone']??'',address:j['address']??'');c.balance=(j['balance']??0).toDouble();return c;}
}
class Entry {
  Entry({required this.product,required this.type,required this.kg,required this.amount,
    required this.date,this.customer='',this.note='',this.paid=0});
  String product,type,date,customer,note;
  double kg,amount,paid;
  Map<String,dynamic> toJson()=>{'product':product,'type':type,'kg':kg,'amount':amount,'date':date,
    'customer':customer,'note':note,'paid':paid};
  factory Entry.fromJson(Map<String,dynamic> j)=>Entry(product:j['product']??'',type:j['type']??'',
    kg:(j['kg']??0).toDouble(),amount:(j['amount']??0).toDouble(),date:j['date']??'',
    customer:j['customer']??'',note:j['note']??'',paid:(j['paid']??0).toDouble());
}

class RiceMillApp extends StatelessWidget {
  const RiceMillApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,
    title:'Rice Mill Manager',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff287a48)),
    useMaterial3:true,scaffoldBackgroundColor:const Color(0xfff5f7f5)),home:const HomePage());
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  final names=['Rice Flour','Cotton Seed','SKM Feeds','KS Feed','Rice Husk'];
  final products=<Product>[], customers=<Customer>[], entries=<Entry>[];
  int tab=0; bool tamil=false;
  String tr(String en,String ta)=>tamil?ta:en;
  String get now=>DateTime.now().toString().substring(0,16);
  double get salesTotal=>entries.where((e)=>e.type=='Sale').fold(0,(s,e)=>s+e.amount);
  double get receivedTotal=>entries.where((e)=>e.type=='Sale').fold(0,(s,e)=>s+e.paid)+entries.where((e)=>e.type=='Payment').fold(0,(s,e)=>s+e.amount);
  double get outstanding=>customers.fold(0,(s,c)=>s+c.balance);
  double get stockTotal=>products.fold(0,(s,p)=>s+p.stockKg);

  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final ps=p.getString('products_v2'), cs=p.getString('customers_v2'), es=p.getString('entries_v2');
    setState((){
      if(ps==null) products.addAll(names.map((n)=>Product(n)));
      else products.addAll((jsonDecode(ps) as List).map((e)=>Product.fromJson(e)));
      if(cs!=null) customers.addAll((jsonDecode(cs) as List).map((e)=>Customer.fromJson(e)));
      if(es!=null) entries.addAll((jsonDecode(es) as List).map((e)=>Entry.fromJson(e)));
    });
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('products_v2',jsonEncode(products.map((e)=>e.toJson()).toList()));
    await p.setString('customers_v2',jsonEncode(customers.map((e)=>e.toJson()).toList()));
    await p.setString('entries_v2',jsonEncode(entries.map((e)=>e.toJson()).toList()));
  }
  void addStock(Product p,String type,double kg,double cost){
    setState((){
      p.stockKg+=kg;
      if(type=='Production'){p.producedKg+=kg;p.productionCost+=cost;}
      else{p.purchasedKg+=kg;p.purchaseCost+=cost;}
      entries.insert(0,Entry(product:p.name,type:type,kg:kg,amount:cost,date:now));
    });save();
  }
  void makeSale(Product p,Customer? c,double qty,String unit,double rate,double paid){
    final kg=unit=='Bag'?qty*p.bagKg:qty;
    if(kg>p.stockKg){toast(tr('Insufficient stock. Available: ${p.stockKg} kg','ஸ்டாக் போதவில்லை. இருப்பு: ${p.stockKg} கிலோ'));return;}
    final total=kg*rate, due=(total-paid).clamp(0,double.infinity);
    setState((){
      p.stockKg-=kg;p.soldKg+=kg;p.salesAmount+=total;
      if(c!=null)c.balance+=due;
      entries.insert(0,Entry(product:p.name,type:'Sale',kg:kg,amount:total,paid:paid,
        date:now,customer:c?.name??'Walk-in'));
    });save();
  }
  void toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  @override Widget build(BuildContext context){
    final labels=[tr('Home','முகப்பு'),tr('Stock','ஸ்டாக்'),tr('Sales','விற்பனை'),tr('Customers','வாடிக்கையாளர்'),tr('Reports','அறிக்கைகள்')];
    return Scaffold(appBar:AppBar(title:Text('🌾 ${tr('Rice Mill Manager','ரைஸ் மில் மேலாளர்')}'),
      actions:[TextButton(onPressed:()=>setState(()=>tamil=!tamil),child:Text(tamil?'தமிழ்':'EN',style:const TextStyle(fontWeight:FontWeight.bold)))]),
      body:IndexedStack(index:tab,children:[dashboard(),stockPage(),salesPage(),customersPage(),reportsPage()]),
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),
        destinations:[NavigationDestination(icon:const Icon(Icons.dashboard_outlined),label:labels[0]),
          NavigationDestination(icon:const Icon(Icons.inventory_2_outlined),label:labels[1]),
          NavigationDestination(icon:const Icon(Icons.point_of_sale),label:labels[2]),
          NavigationDestination(icon:const Icon(Icons.people_outline),label:labels[3]),
          NavigationDestination(icon:const Icon(Icons.analytics_outlined),label:labels[4])]));
  }
  Widget metric(String title,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(14),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:Colors.green),const SizedBox(height:6),
      Text(title,style:const TextStyle(color:Colors.black54)),Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))])));
  Widget dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(tr('Business overview','வணிக சுருக்கம்'),style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:10),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
      childAspectRatio:1.45,crossAxisSpacing:8,mainAxisSpacing:8,children:[
        metric(tr('Available stock','இருப்பு'),'${stockTotal.toStringAsFixed(1)} kg',Icons.inventory),
        metric(tr('Sales total','மொத்த விற்பனை'),'₹${salesTotal.toStringAsFixed(0)}',Icons.currency_rupee),
        metric(tr('Received','வசூல்'),'₹${receivedTotal.toStringAsFixed(0)}',Icons.payments),
        metric(tr('Customer due','பாக்கி'),'₹${outstanding.toStringAsFixed(0)}',Icons.account_balance_wallet)]),
    const SizedBox(height:16),Text(tr('Product stock','பொருள் இருப்பு'),style:Theme.of(context).textTheme.titleMedium),
    ...products.map((p)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.grain)),title:Text(p.name),
      subtitle:Text('${tr('Bag','மூட்டை')}: ${p.bagKg.toStringAsFixed(0)} kg'),trailing:Text('${p.stockKg.toStringAsFixed(1)} kg',
      style:const TextStyle(fontWeight:FontWeight.bold)))))
  ]);

  Widget stockPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(tr('Stock & production','இருப்பு மற்றும் உற்பத்தி'),style:Theme.of(context).textTheme.titleLarge),
    ...products.map((p)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
      Text('${tr('Stock','இருப்பு')}: ${p.stockKg.toStringAsFixed(1)} kg | ${tr('Produced','உற்பத்தி')}: ${p.producedKg.toStringAsFixed(1)} kg | ${tr('Purchased','வாங்கியது')}: ${p.purchasedKg.toStringAsFixed(1)} kg'),
      Wrap(children:[TextButton.icon(onPressed:()=>stockDialog(p,'Production'),icon:const Icon(Icons.factory),label:Text(tr('Production','உற்பத்தி'))),
        TextButton.icon(onPressed:()=>stockDialog(p,'Purchase'),icon:const Icon(Icons.add_shopping_cart),label:Text(tr('Outside purchase','வெளி கொள்முதல்'))),
        IconButton(onPressed:()=>bagDialog(p),icon:const Icon(Icons.scale),tooltip:tr('Set bag kg','மூட்டை எடை'))])
    ])))),
  ]);
  Future<void> stockDialog(Product p,String type)async{
    final kg=TextEditingController(),cost=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('${type=='Production'?tr('Production','உற்பத்தி'):tr('Purchase','கொள்முதல்')} - ${p.name}'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:kg,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('Quantity (kg)','அளவு (கிலோ)'))),
        TextField(controller:cost,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('Total cost (₹)','மொத்த செலவு (₹)')))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr('Cancel','ரத்து'))),FilledButton(onPressed:(){
        final q=double.tryParse(kg.text)??0,v=double.tryParse(cost.text)??0;if(q>0){addStock(p,type,q,v);Navigator.pop(ctx);}},child:Text(tr('Save','சேமி')))]));
  }
  Future<void> bagDialog(Product p)async{final c=TextEditingController(text:p.bagKg.toStringAsFixed(0));
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('${p.name} - ${tr('Bag weight','மூட்டை எடை')}'),
      content:TextField(controller:c,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('1 bag = kg','1 மூட்டை = கிலோ'))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr('Cancel','ரத்து'))),FilledButton(onPressed:(){
        final v=double.tryParse(c.text)??0;if(v>0){setState(()=>p.bagKg=v);save();Navigator.pop(ctx);}},child:Text(tr('Save','சேமி')))]));}

  Widget salesPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(tr('Sales','விற்பனை'),style:Theme.of(context).textTheme.titleLarge),
      FilledButton.icon(onPressed:saleDialog,icon:const Icon(Icons.add),label:Text(tr('New sale','புதிய விற்பனை')))]),
    ...entries.where((e)=>e.type=='Sale').map((e)=>Card(child:ListTile(title:Text(e.product),
      subtitle:Text('${e.customer} • ${e.kg.toStringAsFixed(1)} kg • ${e.date}'),
      trailing:Text('₹${e.amount.toStringAsFixed(2)}'))))
  ]);
  Future<void> saleDialog()async{
    Product selected=products.first;Customer? customer;String unit='Kg';
    final qty=TextEditingController(),rate=TextEditingController(),paid=TextEditingController(text:'0');
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(tr('New sale','புதிய விற்பனை')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<Product>(value:selected,decoration:InputDecoration(labelText:tr('Product','பொருள்')),
          items:products.map((p)=>DropdownMenuItem(value:p,child:Text(p.name))).toList(),onChanged:(v)=>setD(()=>selected=v!)),
        DropdownButtonFormField<Customer?>(value:customer,decoration:InputDecoration(labelText:tr('Customer (optional)','வாடிக்கையாளர் (விருப்பம்)')),
          items:[const DropdownMenuItem<Customer?>(value:null,child:Text('Walk-in')), ...customers.map((c)=>DropdownMenuItem<Customer?>(value:c,child:Text(c.name)))],
          onChanged:(v)=>setD(()=>customer=v)),
        DropdownButtonFormField<String>(value:unit,decoration:InputDecoration(labelText:tr('Unit','அலகு')),
          items:['Kg','Bag'].map((u)=>DropdownMenuItem(value:u,child:Text(u))).toList(),onChanged:(v)=>setD(()=>unit=v!)),
        Text('${tr('Bag size','மூட்டை எடை')}: ${selected.bagKg} kg | ${tr('Available','இருப்பு')}: ${selected.stockKg} kg'),
        TextField(controller:qty,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('Quantity','அளவு'))),
        TextField(controller:rate,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('Rate per kg (₹)','கிலோ விலை (₹)'))),
        TextField(controller:paid,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('Amount received now (₹)','இப்போது பெற்ற தொகை (₹)'))),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr('Cancel','ரத்து'))),FilledButton(onPressed:(){
        final q=double.tryParse(qty.text)??0,r=double.tryParse(rate.text)??0,v=double.tryParse(paid.text)??0;
        if(q>0&&r>0){makeSale(selected,customer,q,unit,r,v);Navigator.pop(ctx);}},child:Text(tr('Save & bill','சேமி & பில்')))])));
  }

  Widget customersPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(tr('Customers & balances','வாடிக்கையாளர் / பாக்கி'),style:Theme.of(context).textTheme.titleLarge),
      FilledButton.icon(onPressed:customerDialog,icon:const Icon(Icons.person_add),label:Text(tr('Add','சேர்')))]),
    const SizedBox(height:8),
    ...customers.map((c)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(c.name),
      subtitle:Text('${c.phone}\n${c.address}'),isThreeLine:true,trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Text('₹${c.balance.toStringAsFixed(0)}',style:const TextStyle(fontWeight:FontWeight.bold,color:Colors.deepOrange)),
        TextButton(onPressed:()=>paymentDialog(c),child:Text(tr('Receive','வசூல்')))])))),
    if(customers.isEmpty)Padding(padding:const EdgeInsets.all(24),child:Text(tr('No customers yet. Tap Add to create one.','வாடிக்கையாளர் இல்லை. சேர் என்பதை அழுத்தவும்.')))
  ]);
  Future<void> customerDialog()async{
    final name=TextEditingController(),phone=TextEditingController(),address=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(tr('Add customer','வாடிக்கையாளர் சேர்க்க')),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:InputDecoration(labelText:tr('Customer name','பெயர்'))),
        TextField(controller:phone,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:tr('Phone','தொலைபேசி'))),
        TextField(controller:address,decoration:InputDecoration(labelText:tr('Address','முகவரி')))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr('Cancel','ரத்து'))),FilledButton(onPressed:(){
        if(name.text.trim().isNotEmpty){setState(()=>customers.add(Customer(name.text.trim(),phone:phone.text,address:address.text)));save();Navigator.pop(ctx);}},child:Text(tr('Save','சேமி')))]));
  }
  Future<void> paymentDialog(Customer c)async{
    final amount=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('${tr('Receive payment','பணம் வசூல்')} - ${c.name}'),
      content:TextField(controller:amount,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr('Amount (₹)','தொகை (₹)'))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr('Cancel','ரத்து'))),FilledButton(onPressed:(){
        final v=double.tryParse(amount.text)??0;if(v>0){final applied=v>c.balance?c.balance:v;setState(()=>c.balance-=applied);
          entries.insert(0,Entry(product:'-',type:'Payment',kg:0,amount:applied,date:now,customer:c.name,note:'Payment received'));save();Navigator.pop(ctx);}},child:Text(tr('Save','சேமி')))]));
  }

  Widget reportsPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(tr('Business reports','வணிக அறிக்கைகள்'),style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:10),
    metric(tr('Total sales','மொத்த விற்பனை'),'₹${salesTotal.toStringAsFixed(2)}',Icons.trending_up),
    metric(tr('Payments received','பெற்ற பணம்'),'₹${receivedTotal.toStringAsFixed(2)}',Icons.payments),
    metric(tr('Outstanding customer balance','வாடிக்கையாளர் பாக்கி'),'₹${outstanding.toStringAsFixed(2)}',Icons.account_balance_wallet),
    const SizedBox(height:12),
    FilledButton.icon(onPressed:exportSummary,icon:const Icon(Icons.picture_as_pdf),label:Text(tr('Export PDF report','PDF அறிக்கை உருவாக்கு'))),
    const SizedBox(height:8),Text(tr('Note: Profit is not yet calculated because stock valuation and expense categories need to be configured.','குறிப்பு: செலவுகள் மற்றும் இருப்பு மதிப்பு அமைக்கப்பட்ட பிறகே நிகர லாபம் கணக்கிடப்படும்.'))
  ]);

  Future<Uint8List> buildInvoice(Entry e)async{
    final doc=pw.Document();
    doc.addPage(pw.Page(pageFormat:PdfPageFormat.a4,build:(ctx)=>pw.Padding(padding:const pw.EdgeInsets.all(28),
      child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
        pw.Text('RICE MILL MANAGER',style:pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold)),
        pw.SizedBox(height:8),pw.Text('SALES INVOICE',style:const pw.TextStyle(fontSize:16)),
        pw.Divider(),pw.Text('Date: ${e.date}'),pw.Text('Customer: ${e.customer}'),
        pw.SizedBox(height:20),pw.Table.fromTextArray(headers:['Product','Quantity (kg)','Amount (INR)'],
          data:[[e.product,e.kg.toStringAsFixed(2),e.amount.toStringAsFixed(2)]]),
        pw.SizedBox(height:16),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('Total: INR ${e.amount.toStringAsFixed(2)}',
          style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold))),
        pw.Text('Received: INR ${e.paid.toStringAsFixed(2)}'),
        pw.Text('Balance: INR ${(e.amount-e.paid).clamp(0,double.infinity).toStringAsFixed(2)}'),
        pw.Spacer(),pw.Text('Thank you for your business.')
      ]))));
    return doc.save();
  }
  Future<void> exportSummary()async{
    final doc=pw.Document();
    doc.addPage(pw.Page(build:(ctx)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text('Rice Mill Manager - Business Summary',style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:12),pw.Text('Total sales: INR ${salesTotal.toStringAsFixed(2)}'),
      pw.Text('Payments received: INR ${receivedTotal.toStringAsFixed(2)}'),
      pw.Text('Customer outstanding: INR ${outstanding.toStringAsFixed(2)}'),
      pw.SizedBox(height:14),pw.Table.fromTextArray(headers:['Product','Stock kg','Produced kg','Purchased kg','Sold kg'],
        data:products.map((p)=>[p.name,p.stockKg.toStringAsFixed(1),p.producedKg.toStringAsFixed(1),p.purchasedKg.toStringAsFixed(1),p.soldKg.toStringAsFixed(1)]).toList())
    ])));
    await Printing.layoutPdf(onLayout:(format)async=>doc.save());
  }
}
